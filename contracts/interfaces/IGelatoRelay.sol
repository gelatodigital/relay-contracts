// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IGelatoRelayBase1Balance} from "./IGelatoRelayBase1Balance.sol";
import {
    SponsorAuthCallWith1Balance,
    UserAuthCallWith1Balance,
    UserSponsorAuthCallWith1Balance
} from "../types/CallTypes.sol";

interface IGelatoRelay is IGelatoRelayBase1Balance {
    event LogCallWithSyncFee(
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    function callWithSyncFee(
        address _target,
        bytes calldata _data,
        address _feeToken,
        uint256 _fee,
        bytes32 _taskId
    ) external;

    function sponsorAuthCallWith1Balance(
        SponsorAuthCallWith1Balance calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;

    function userAuthCallWith1Balance(
        UserAuthCallWith1Balance calldata _call,
        bytes calldata _userSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;

    function userSponsorAuthCallWith1Balance(
        UserSponsorAuthCallWith1Balance calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;
}
