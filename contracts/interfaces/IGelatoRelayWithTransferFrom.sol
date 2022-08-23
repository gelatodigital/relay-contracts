// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    SponsorAuthCallWithTransferFrom,
    UserAuthCallWithTransferFrom,
    UserSponsorAuthCallWithTransferFrom
} from "../types/CallTypes.sol";

interface IGelatoRelayWithTransferFrom {
    event LogSponsorAuthCallWithTransferFrom(
        address indexed sponsor,
        address indexed target,
        address indexed feeToken,
        uint256 fee,
        bytes32 taskId
    );
    event LogUserAuthCallWithTransferFrom(
        address indexed user,
        address indexed target,
        address indexed feeToken,
        uint256 fee,
        bytes32 taskId
    );
    event LogUserSponsorAuthCallWithTransferFrom(
        address indexed sponsor,
        address indexed target,
        address indexed feeToken,
        uint256 fee,
        address user,
        bytes32 taskId
    );

    function pause() external;

    function unpause() external;

    function sponsorAuthCall(
        SponsorAuthCallWithTransferFrom calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;

    function userAuthCall(
        UserAuthCallWithTransferFrom calldata _call,
        bytes calldata _userSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;

    function userSponsorAuthCall(
        UserSponsorAuthCallWithTransferFrom calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;

    function gelatoRelayAllowances() external view returns (address);
}
