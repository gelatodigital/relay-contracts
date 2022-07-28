// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    SponsorAuthCall,
    UserAuthCall,
    UserSponsorAuthCall
} from "../types/CallTypes.sol";

interface IGelatoRelay {
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
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;

    function sponsorAuthCallWith1Balance(
        SponsorAuthCall calldata _call,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;

    function userAuthCallWith1Balance(
        UserAuthCall calldata _call,
        bytes calldata _userSignature,
        uint256 _gelatoFee,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;

    function userSponsorAuthCallWith1Balance(
        UserSponsorAuthCall calldata _call,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;
}
