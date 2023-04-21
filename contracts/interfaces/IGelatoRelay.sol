// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGelatoRelay {
    event LogCallWithSyncFeeV2(
        address indexed target,
        bytes32 indexed correlationId
    );

    function gelato() external view returns (address);

    function callWithSyncFeeV2(
        address _target,
        bytes calldata _data,
        bool _isRelayContext,
        bytes32 _correlationId
    ) external;
}
