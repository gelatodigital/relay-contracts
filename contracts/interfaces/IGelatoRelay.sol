// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    SponsoredCall,
    UserAuthCall,
    SponsoredUserAuthCall
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
        uint256 _fee,
        bytes32 _taskId
    ) external;

    function sponsoredCall(
        SponsoredCall calldata _call,
        address _sponsor,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;

    function userAuthCall(
        UserAuthCall calldata _call,
        bytes calldata _userSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;

    function sponsoredUserAuthCall(
        SponsoredUserAuthCall calldata _call,
        address _sponsor,
        bytes calldata _userSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external;
}
