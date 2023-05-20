// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IGelatoRelay {
    event LogCallWithSyncFeeV2(
        address indexed target,
        bytes32 indexed correlationId
    );

    function callWithSyncFeeV2(
        address _target,
        bytes calldata _data,
        bool _isRelayContext,
        bytes32 _correlationId
    ) external;

    function gelato() external view returns (address);
}
