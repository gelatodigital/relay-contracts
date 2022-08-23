// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    IGelatoRelayWithTransferFrom
} from "./interfaces/IGelatoRelayWithTransferFrom.sol";
import {
    GelatoRelayBaseTransferFrom
} from "./abstract/GelatoRelayBaseTransferFrom.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {GelatoCallUtils} from "./lib/GelatoCallUtils.sol";
import {_eip2771Context} from "./functions/ContextUtils.sol";
import {
    SponsorAuthCallWithTransferFrom,
    UserAuthCallWithTransferFrom,
    UserSponsorAuthCallWithTransferFrom
} from "./types/CallTypes.sol";
import {IGelatoRelayAllowances} from "./interfaces/IGelatoRelayAllowances.sol";
import {PaymentType} from "./types/PaymentTypes.sol";

/// @title  Gelato Relay with TransferFrom contract
/// @notice This contract deals with synchronous native/ERC-20 payments via transferFrom
/// @dev    This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here
contract GelatoRelayWithTransferFrom is
    IGelatoRelayWithTransferFrom,
    GelatoRelayBaseTransferFrom,
    Ownable,
    Pausable
{
    using GelatoCallUtils for address;

    address public immutable gelatoRelayAllowances;

    //solhint-disable-next-line const-name-snakecase
    string public constant name = "GelatoRelayWithTransferFrom";
    //solhint-disable-next-line const-name-snakecase
    string public constant version = "1";

    constructor(address _gelato, address _gelatoRelayAllowances)
        GelatoRelayBaseTransferFrom(_gelato)
    {
        gelatoRelayAllowances = _gelatoRelayAllowances;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Relay call + transferFrom from sponsor
    /// @notice Sponsor authentication via signature allows for payment with sponsor's feeToken
    /// @dev    Assumes that _call.sponsor has approved this contract to spend _call.feeToken
    /// @param _call Relay call data packed into SponsorAuthCall struct
    /// @param _sponsorSignature EIP-712 compliant signature from _call.sponsor
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function sponsorAuthCall(
        SponsorAuthCallWithTransferFrom calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        // CHECKS
        require(
            _call.paymentType == PaymentType.TransferFrom,
            "GelatoRelayWithTransferFrom.sponsorAuthCall: paymentType"
        );

        _requireChainId(
            _call.chainId,
            "GelatoRelayWithTransferFrom.sponsorAuthCall:"
        );

        _requireMaxFee(
            _gelatoFee,
            _call.maxFee,
            "GelatoRelayWithTransferFrom.sponsorAuthCall:"
        );

        require(
            _call.target != gelatoRelayAllowances,
            "GelatoRelayWithTransferFrom.sponsorAuthCall: call denied"
        );

        // Do not enforce ordering on nonces,
        // but still enforce replay protection
        // via uniqueness of message
        bytes32 digest = _requireSponsorAuthCallSignatureTransferFrom(
            _getDomainSeparator(),
            _call,
            _sponsorSignature,
            _call.sponsor
        );
        require(
            !wasCallSponsoredAlready[digest],
            "GelatoRelayWithTransferFrom.sponsorAuthCall: replay"
        );

        // EFFECTS
        wasCallSponsoredAlready[digest] = true;

        // INTERACTIONS
        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelayWithTransferFrom.sponsorAuthCall:"
        );

        IGelatoRelayAllowances(gelatoRelayAllowances).transferFrom(
            _call.feeToken,
            _call.sponsor,
            _gelatoFee
        );

        emit LogSponsorAuthCallWithTransferFrom(
            _call.sponsor,
            _call.target,
            _call.feeToken,
            _gelatoFee,
            _taskId
        );
    }

    /// @notice Relay call + transferFrom from user
    /// @notice User authentication via signature allows for payment with user's feeToken
    /// @dev    Assumes that _call.user has approved this contract to spend _call.feeToken
    /// @param _call Relay call data packed into UserAuthCall struct
    /// @param _userSignature EIP-712 compliant signature from _call.user
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function userAuthCall(
        UserAuthCallWithTransferFrom calldata _call,
        bytes calldata _userSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        // CHECKS
        require(
            _call.paymentType == PaymentType.TransferFrom,
            "GelatoRelayWithTransferFrom.userAuthCall: paymentType"
        );

        _requireChainId(
            _call.chainId,
            "GelatoRelayWithTransferFrom.userAuthCall:"
        );

        _requireMaxFee(
            _gelatoFee,
            _call.maxFee,
            "GelatoRelayWithTransferFrom.userAuthCall:"
        );

        uint256 storedUserNonce = userNonce[_call.user];

        // For the user, we enforce nonce ordering
        _requireUserBasics(
            _call.userNonce,
            storedUserNonce,
            _call.userDeadline,
            "GelatoRelayWithTransferFrom.userAuthCall:"
        );

        require(
            _call.target != gelatoRelayAllowances,
            "GelatoRelayWithTransferFrom.userAuthCall: call denied"
        );

        _requireUserAuthCallSignatureTransferFrom(
            _getDomainSeparator(),
            _call,
            _userSignature,
            _call.user
        );

        // EFFECTS
        userNonce[_call.user] = storedUserNonce + 1;

        // INTERACTIONS
        _call.target.revertingContractCall(
            _eip2771Context(_call.data, _call.user),
            "GelatoRelayWithTransferFrom.userAuthCall:"
        );

        IGelatoRelayAllowances(gelatoRelayAllowances).transferFrom(
            _call.feeToken,
            _call.user,
            _gelatoFee
        );

        emit LogUserAuthCallWithTransferFrom(
            _call.user,
            _call.target,
            _call.feeToken,
            _gelatoFee,
            _taskId
        );
    }

    /// @notice Relay call + transferFrom from sponsor - with BOTH sponsor and user authentication
    /// @notice Both sponsor and user signature allows for payment via sponsor's feeToken
    /// @dev    Assumes that _call.sponsor has approved this contract to spend _call.feeToken
    /// @param _call Relay call data packed into userSponsorAuthCall
    /// @param _userSignature EIP-712 compliant signature from _call.user
    /// @param _sponsorSignature EIP-712 compliant signature from _call.sponsor
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function userSponsorAuthCall(
        UserSponsorAuthCallWithTransferFrom calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        // CHECKS
        require(
            _call.paymentType == PaymentType.TransferFrom,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: paymentType"
        );

        _requireChainId(
            _call.chainId,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall:"
        );

        _requireMaxFee(
            _gelatoFee,
            _call.maxFee,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall:"
        );

        uint256 storedUserNonce = userNonce[_call.user];

        // For the user, we enforce nonce ordering
        _requireUserBasics(
            _call.userNonce,
            storedUserNonce,
            _call.userDeadline,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall:"
        );

        require(
            _call.target != gelatoRelayAllowances,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: call denied"
        );

        bytes32 domainSeparator = _getDomainSeparator();

        // Verify user's signature
        _requireUserSponsorAuthCallSignatureTransferFrom(
            domainSeparator,
            _call,
            _userSignature,
            _call.user
        );

        // Verify sponsor's signature
        // Do not enforce ordering on nonces but still enforce replay protection
        // via uniqueness of call with nonce
        bytes32 digest = _requireUserSponsorAuthCallSignatureTransferFrom(
            domainSeparator,
            _call,
            _sponsorSignature,
            _call.sponsor
        );

        // Sponsor replay protection
        require(
            !wasCallSponsoredAlready[digest],
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: replay"
        );

        // EFFECTS
        userNonce[_call.user] = storedUserNonce + 1;
        wasCallSponsoredAlready[digest] = true;

        // INTERACTIONS
        _call.target.revertingContractCall(
            _eip2771Context(_call.data, _call.user),
            "GelatoRelayWithTransferFrom.userSponsorAuthCall:"
        );

        IGelatoRelayAllowances(gelatoRelayAllowances).transferFrom(
            _call.feeToken,
            _call.sponsor,
            _gelatoFee
        );

        emit LogUserSponsorAuthCallWithTransferFrom(
            _call.sponsor,
            _call.target,
            _call.feeToken,
            _gelatoFee,
            _call.user,
            _taskId
        );
    }

    //solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _getDomainSeparator();
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            //solhint-disable-next-line max-line-length
                            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                        )
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this)
                )
            );
    }
}
