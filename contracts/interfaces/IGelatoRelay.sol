// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SponsoredCall, SponsoredUserAuthCall} from "../types/CallTypes.sol";

interface IGelatoRelay {
    event LogCallWithSyncFee(
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogCallWithSyncFeeV2(
        address indexed target,
        bytes32 indexed correlationId
    );

    function callWithSyncFee(
        address _target,
        bytes calldata _data,
        address _feeToken,
        uint256 _fee,
        bytes32 _taskId
    ) external;

    function callWithSyncFeeV2(
        address _target,
        bytes calldata _data,
        bool _relayContext,
        bytes32 _correlationId
    ) external;

    function sponsoredCall(
        SponsoredCall calldata _call,
        address _sponsor,
        address _feeToken,
        uint256 _oneBalanceChainId,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _correlationId
    ) external;

    function sponsoredUserAuthCall(
        SponsoredUserAuthCall calldata _call,
        address _sponsor,
        address _feeToken,
        uint256 _oneBalanceChainId,
        bytes calldata _userSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _correlationId
    ) external;
}
