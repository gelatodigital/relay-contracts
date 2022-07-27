// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GelatoRelayBase} from "./base/GelatoRelayBase.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {GelatoCallUtils} from "./lib/GelatoCallUtils.sol";
import {SponsorAuthCall} from "./types/CallTypes.sol";
import {UserSponsorAuthCall} from "./types/CallTypes.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {IGelato} from "./interfaces/IGelato.sol";
import {IGelatoRelayAllowances} from "./interfaces/IGelatoRelayAllowances.sol";
import {PaymentType} from "./types/PaymentTypes.sol";

contract GelatoRelayPullFee is GelatoRelayBase, Ownable, Pausable {
    using GelatoCallUtils for address;

    address public immutable gelatoRelayAllowances;

    mapping(address => uint256) public nonce;
    mapping(bytes32 => bool) public isSponsoredCallReplayed;

    event LogSponsorAuthCallPullFee(
        address indexed sponsor,
        address indexed target,
        address indexed feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogUserSponsorAuthCallPullFee(
        address indexed sponsor,
        address indexed target,
        address indexed feeToken,
        uint256 fee,
        address user,
        bytes32 taskId
    );

    constructor(address _gelato, address _gelatoRelayAllowances)
        GelatoRelayBase(_gelato)
    {
        gelatoRelayAllowances = _gelatoRelayAllowances;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Relay forward request + pull fee from (transferFrom) _call.sponsor's address
    /// @dev    Assumes that _call.sponsor has approved this contract to spend _call.feeToken
    /// @param _call Relay request data
    /// @param _sponsorSignature EIP-712 compliant signature from _call.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function sponsorAuthCallPullFee(
        SponsorAuthCall calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        require(
            _call.chainId == block.chainid,
            "GelatoRelayPullFee.sponsorAuthCallPullFee: chainId"
        );

        require(
            _call.paymentType == PaymentType.PullFee,
            "GelatoRelayPullFee.sponsorAuthCallPullFee: paymentType"
        );

        require(
            _call.feeToken != NATIVE_TOKEN,
            "GelatoRelayPullFee.sponsorAuthCallPullFee: only ERC-20"
        );

        require(
            _gelatoFee <= _call.maxFee,
            "GelatoRelayPullFee.sponsorAuthCallPullFee: maxFee"
        );

        // Verify and increment sponsor's nonce
        // We assume that all security is enforced on _call.target address,
        // hence we allow the sponsor to submit multiple transactions concurrently
        // In case one reverts, it won't stop the others from being executed

        // Optionally, the dApp may not want to track smart contract nonces
        // We allow this option, BUT MAKE SURE _call.target implements strong replay protection!
        if (_call.enforceSponsorNonce) {
            if (_call.enforceSponsorNonceOrdering) {
                // Enforce ordering on nonces,
                // If tx with nonce n reverts, so will tx with nonce n+1.
                require(
                    _call.nonce == nonce[_call.sponsor],
                    "GelatoRelayPullFee.sponsorAuthCallPullFee: nonce"
                );
                nonce[_call.sponsor] = _call.nonce + 1;

                _verifySponsorAuthCallSignature(
                    _call,
                    _sponsorSignature,
                    _call.sponsor
                );
            } else {
                // Do not enforce ordering on nonces,
                // but still enforce replay protection
                // via uniqueness of message
                bytes32 message = _verifySponsorAuthCallSignature(
                    _call,
                    _sponsorSignature,
                    _call.sponsor
                );
                require(
                    !isSponsoredCallReplayed[message],
                    "GelatoRelayPullFee.sponsorAuthCallPullFee: replay"
                );
                isSponsoredCallReplayed[message] = true;
            }
        } else {
            _verifySponsorAuthCallSignature(
                _call,
                _sponsorSignature,
                _call.sponsor
            );
        }

        _verifySponsorAuthCallSignature(
            _call,
            _sponsorSignature,
            _call.sponsor
        );

        // Gas optimization
        address gelatoRelayAllowancesCopy = gelatoRelayAllowances;

        require(
            _call.target != gelatoRelayAllowancesCopy,
            "GelatoRelayPullFee.sponsorAuthCallPullFee: call to pullFeeRegistry"
        );

        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelayPullFee.sponsorAuthCallPullFee:"
        );

        IGelatoRelayAllowances(gelatoRelayAllowancesCopy).pullFeeFrom(
            _call.feeToken,
            _call.sponsor,
            _gelatoFee
        );

        emit LogSponsorAuthCallPullFee(
            _call.sponsor,
            _call.target,
            _call.feeToken,
            _gelatoFee,
            _taskId
        );
    }

    /// @notice Relay meta tx request + pull fee from (transferFrom) _call.sponsor's address
    /// @dev    Assumes that _call.sponsor has approved this contract to spend _call.feeToken
    /// @param _call Relay request data
    /// @param _userSignature EIP-712 compliant signature from _call.user
    /// @param _sponsorSignature EIP-712 compliant signature from _call.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    /// @notice Handles the case of tokens with fee on transfer
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function userSponsorAuthCallPullFee(
        UserSponsorAuthCall calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        require(
            // solhint-disable-next-line not-rely-on-time
            _call.userDeadline == 0 || _call.userDeadline >= block.timestamp,
            "GelatoRelayPullFee.userSponsorAuthCallPullFee: Request expired"
        );

        require(
            _call.chainId == block.chainid,
            "GelatoRelayPullFee.userSponsorAuthCallPullFee: chainId"
        );

        require(
            _call.paymentType == PaymentType.PullFee,
            "GelatoRelayPullFee.userSponsorAuthCallPullFee: paymentType"
        );

        require(
            _call.feeToken != NATIVE_TOKEN,
            "GelatoRelayPullFee.userSponsorAuthCallPullFee: only ERC-20"
        );

        require(
            _gelatoFee <= _call.maxFee,
            "GelatoRelayPullFee.userSponsorAuthCallPullFee: maxFee"
        );

        // Verify and increment user's nonce
        require(
            _call.nonce == userNonce[_call.user],
            "GelatoRelayPullFee.userSponsorAuthCallPullFee: nonce"
        );
        userNonce[_call.user]++;

        _verifyUserSponsorAuthCallSignature(_call, _userSignature, _call.user);
        // If is sponsored tx, we also verify sponsor's signature
        if (_call.user != _call.sponsor) {
            _verifyUserSponsorAuthCallSignature(
                _call,
                _sponsorSignature,
                _call.sponsor
            );
        }

        address gelatoRelayAllowancesCopy = gelatoRelayAllowances;

        require(
            _call.target != gelatoRelayAllowancesCopy,
            "GelatoRelayPullFee.userSponsorAuthCallPullFee: call to pullFeeRegistry"
        );

        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelayPullFee.userSponsorAuthCallPullFee:"
        );

        IGelatoRelayAllowances(gelatoRelayAllowancesCopy).pullFeeFrom(
            _call.feeToken,
            _call.sponsor,
            _gelatoFee
        );

        emit LogUserSponsorAuthCallPullFee(
            _call.sponsor,
            _call.target,
            _call.feeToken,
            _gelatoFee,
            _call.user,
            _taskId
        );
    }

    function getDomainSeparator() public view override returns (bytes32) {
        return _getDomainSeparator(block.chainid);
    }
}
