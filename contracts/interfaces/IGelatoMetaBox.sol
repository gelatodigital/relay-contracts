// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import {SponsorAuthCall, UserSponsorAuthCall} from "../types/CallTypes.sol";

interface IGelatoMetaBox {
    function forwardedRequestOneBalance(
        SponsorAuthCall calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;

    function userSponsorAuthCallOneBalance(
        UserSponsorAuthCall calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;
}
