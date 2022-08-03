// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    IGelatoRelayWithTransferFrom
} from "./interfaces/IGelatoRelayWithTransferFrom.sol";
import {GelatoRelayBase} from "./GelatoRelayBase.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {GelatoCallUtils} from "./lib/GelatoCallUtils.sol";
import {
    SponsorAuthCall,
    UserAuthCall,
    UserSponsorAuthCall
} from "./types/CallTypes.sol";
import {IGelatoRelayAllowances} from "./interfaces/IGelatoRelayAllowances.sol";
import {PaymentType} from "./types/PaymentTypes.sol";

/// @title  Gelato Relay with TransferFrom contract
/// @notice This contract deals with synchronous native/ERC-20 payments via transferFrom
/// @dev    This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here
contract GelatoRelayWithTransferFrom is
    IGelatoRelayWithTransferFrom,
    GelatoRelayBase,
    Ownable,
    Pausable
{
    using GelatoCallUtils for address;

    address public immutable gelatoRelayAllowances;

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

    /// @notice Relay call + transferFrom from sponsor
    /// @notice Sponsor authentication via signature allows for payment with sponsor's feeToken
    /// @dev    Assumes that _call.sponsor has approved this contract to spend _call.feeToken
    /// @param _call Relay call data packed into SponsorAuthCall struct
    /// @param _sponsorSignature EIP-712 compliant signature from _call.sponsor
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _call.feeToken
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function sponsorAuthCall(
        SponsorAuthCall calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        // CHECKS
        require(
            _call.paymentType == PaymentType.WithTransferFrom,
            "GelatoRelayWithTransferFrom.sponsorAuthCall: paymentType"
        );
        _requireBasics(
            _call.chainId,
            _gelatoFee,
            _call.maxFee,
            "GelatoRelayWithTransferFrom.sponsorAuthCall: "
        );

        address gelatoRelayAllowancesCopy = gelatoRelayAllowances;
        require(
            _call.target != gelatoRelayAllowancesCopy,
            "GelatoRelayWithTransferFrom.sponsorAuthCall: call denied"
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
            "GelatoRelayWithTransferFrom.sponsorAuthCall: replay"
        );

        // EFFECTS
        wasCallSponsoredAlready[digest] = true;

        // INTERACTIONS
        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelayWithTransferFrom.sponsorAuthCall: "
        );

        IGelatoRelayAllowances(gelatoRelayAllowancesCopy).transferFrom(
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
        emit LogSponsorNonce(_call.sponsor, _call.sponsorSalt);
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
        UserAuthCall calldata _call,
        bytes calldata _userSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        // CHECKS
        require(
            _call.paymentType == PaymentType.WithTransferFrom,
            "GelatoRelayWithTransferFrom.userAuthCall: paymentType"
        );
        _requireBasics(
            _call.chainId,
            _gelatoFee,
            _call.maxFee,
            "GelatoRelayWithTransferFrom.userAuthCall: "
        );

        // For the user, we enforce nonce ordering
        _requireUserBasics(
            _call.userNonce,
            userNonce[_call.user],
            _call.userDeadline,
            "GelatoRelayWithTransferFrom.userAuthCall: "
        );

        address gelatoRelayAllowancesCopy = gelatoRelayAllowances;
        require(
            _call.target != gelatoRelayAllowancesCopy,
            "GelatoRelayWithTransferFrom.userAuthCall: call denied"
        );

        _verifyUserAuthCallSignature(_call, _userSignature, _call.user);

        // EFFECTS
        userNonce[_call.user]++;

        // INTERACTIONS
        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelayWithTransferFrom.userAuthCall: "
        );

        IGelatoRelayAllowances(gelatoRelayAllowancesCopy).transferFrom(
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
        UserSponsorAuthCall calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        // CHECKS
        require(
            _call.paymentType == PaymentType.WithTransferFrom,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: paymentType"
        );
        _requireBasics(
            _call.chainId,
            _gelatoFee,
            _call.maxFee,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: "
        );

        // For the user, we enforce nonce ordering
        _requireUserBasics(
            _call.userNonce,
            userNonce[_call.user],
            _call.userDeadline,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: "
        );

        address gelatoRelayAllowancesCopy = gelatoRelayAllowances;
        require(
            _call.target != gelatoRelayAllowancesCopy,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: call denied"
        );

        // Verify user's signature
        _verifyUserSponsorAuthCallSignature(_call, _userSignature, _call.user);

        // Verify sponsor's signature
        // Do not enforce ordering on nonces but still enforce replay protection
        // via uniqueness of call with nonce
        bytes32 digest = _verifyUserSponsorAuthCallSignature(
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
        userNonce[_call.user]++;
        wasCallSponsoredAlready[digest] = true;

        // INTERACTIONS
        _call.target.revertingContractCall(
            _call.data,
            "GelatoRelayWithTransferFrom.userSponsorAuthCall: "
        );

        IGelatoRelayAllowances(gelatoRelayAllowancesCopy).transferFrom(
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
}
