// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {GelatoRelayBase} from "./base/GelatoRelayBase.sol";
import {GelatoCallUtils} from "./lib/GelatoCallUtils.sol";
import {_transfer, _getBalance} from "./utils/Utils.sol";
import {SponsorAuthCall} from "./types/CallTypes.sol";
import {UserSponsorAuthCall} from "./types/CallTypes.sol";
import {IGelato} from "./interfaces/IGelato.sol";
import {PaymentType} from "./types/PaymentTypes.sol";

/// @title Gelato Relay contract
/// @notice This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here.
// solhint-disable-next-line max-states-count
contract GelatoRelay is Proxied, GelatoRelayBase {
    using GelatoCallUtils for address;

    mapping(address => uint256) public userNonce;

    mapping(bytes32 => bool) public wasCallSponsoredAlready;

    event LogCallWithSyncFee(
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogUseGelato1Balance(
        address indexed sponsor,
        address indexed target,
        address indexed feeToken,
        uint256 sponsorChainId,
        uint256 nativeToFeeTokenXRateNumerator,
        uint256 nativeToFeeTokenXRateDenominator,
        bytes32 taskId
    );

    event LogSponsorNonce(address indexed sponsor, uint256 sponsorNonce);

    // solhint-disable-next-line no-empty-blocks
    constructor(address _gelato) GelatoRelayBase(_gelato) {}

    /// @notice Relay request + Sync Payment (target pays Gelato during call forward)
    /// @param _target Target smart contract
    /// @param _data Payload for call on _target
    /// @param _feeToken payment can be done in any whitelisted token
    /// @param _gelatoFee Fee to be charged, denominated in feeToken
    /// @param _taskId Unique task indentifier
    function callWithSyncFee(
        address _target,
        bytes calldata _data,
        address _feeToken,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        uint256 preBalance = _getBalance(_feeToken, address(this));

        _target.revertingContractCall(_data, "GelatoRelay.callWithSyncFee:");

        uint256 postBalance = _getBalance(_feeToken, address(this));

        uint256 amount = postBalance - preBalance;
        require(amount >= _gelatoFee, "Insufficient fee");

        _transfer(_feeToken, IGelato(gelato).getFeeCollector(), amount);

        emit LogCallWithSyncFee(_target, _feeToken, amount, _taskId);
    }

    /// @notice Relay request + One Balance
    /// @param _call Relay request data
    /// @param _sponsorSignature EIP-712 compliant signature from _call.sponsor
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    /// @notice Oracle value for exchange rate between native tokens and fee token
    /// @param  _nativeToFeeTokenXRateNumerator Exchange rate numerator
    /// @param  _nativeToFeeTokenXRateNumerator Exchange rate numerator
    /// @param _taskId Unique task indentifier
    // solhint-disable-next-line function-max-lines
    function callWithOneBalance(
        SponsorAuthCall calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external onlyGelato {
        require(
            _call.chainId == block.chainid,
            "GelatoRelay.callWithOneBalance: chainId"
        );

        require(
            _call.paymentType == PaymentType.OneBalance,
            "GelatoRelay.callWithOneBalance: paymentType must be OneBalance"
        );

        require(
            _gelatoFee <= _call.maxFee,
            "GelatoRelay.callWithOneBalance: maxFee"
        );

        // Do not enforce ordering on nonces,
        // but still enforce replay protection
        // via uniqueness of message
        bytes32 digest = _verifySponsorAuthCallSignature(
            _call,
            _sponsorSignature,
            _call.sponsor
        );
        require(
            !wasCallSponsoredAlready[digest],
            "GelatoRelay.callWithOneBalance: replay"
        );
        wasCallSponsoredAlready[digest] = true;

        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelay.callWithOneBalance:"
        );

        emit LogUseGelato1Balance(
            _call.sponsor,
            _call.target,
            _call.feeToken,
            _call.sponsorChainId,
            _nativeToFeeTokenXRateNumerator,
            _nativeToFeeTokenXRateDenominator,
            _taskId
        );

        emit LogSponsorNonce(_call.sponsor, _call.sponsorNonce);
    }

    /// @notice Relay request + One Balance
    /// @param _call Relay request data
    /// @param _userSignature EIP-712 compliant signature from _call.user
    /// @param _sponsorSignature EIP-712 compliant signature from _call.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    // solhint-disable-next-line function-max-lines
    function userSponsorAuthCallWithOneBalance(
        UserSponsorAuthCall calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external onlyGelato {
        require(
            // solhint-disable-next-line not-rely-on-time
            _call.userDeadline == 0 || _call.userDeadline >= block.timestamp,
            "Request expired"
        );

        require(
            _call.chainId == block.chainid,
            "GelatoRelay.userSponsorAuthCallWithOneBalance: chainId"
        );

        require(
            _call.paymentType == PaymentType.OneBalance,
            "GelatoRelay.userSponsorAuthCallWithOneBalance: paymentType"
        );

        require(
            _gelatoFee <= _call.maxFee,
            "GelatoRelay.userSponsorAuthCallWithOneBalance: maxFee"
        );

        // Verify and increment user's nonce
        require(
            _call.nonce == userNonce[_call.user],
            "GelatoRelay.userSponsorAuthCallWithOneBalance: nonce"
        );

        userNonce[_call.user]++;

        _verifyUserSponsorAuthCallSignature(_call, _userSignature, _call.user);

        // If is sponsored tx, we also verify sponsor's signature
        if (_call.user != _call.sponsor) {
            // Do not enforce ordering on nonces,
            // but still enforce replay protection
            // via uniqueness of call with nonce
            bytes32 digest = _verifyUserSponsorAuthCallSignature(
                _call,
                _sponsorSignature,
                _call.sponsor
            );
            require(
                !wasCallSponsoredAlready[digest],
                "GelatoRelay.callWithOneBalance: replay"
            );
            wasCallSponsoredAlready[digest] = true;
        }

        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelay.userSponsorAuthCallOneBalance:"
        );

        emit LogUseGelato1Balance(
            _call.sponsor,
            _call.target,
            _call.feeToken,
            _call.sponsorChainId,
            _nativeToFeeTokenXRateNumerator,
            _nativeToFeeTokenXRateDenominator,
            _taskId
        );
        emit LogSponsorNonce(_call.sponsor, _call.sponsorNonce);
    }
}
