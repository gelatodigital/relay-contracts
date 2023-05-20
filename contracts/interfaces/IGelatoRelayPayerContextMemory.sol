// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {RelayContext} from "../types/CallTypes.sol";

interface IGelatoRelayPayerContextMemory {
    event LogCallWithSyncFeeStoreContext(
        address indexed target,
        bytes32 indexed correlationId
    );

    function callWithSyncFeeStoreContext(
        address _target,
        bytes calldata _data,
        bytes32 _correlationId
    ) external;

    function transferFeeDelegateCall(address _target) external;

    function transferFeeCappedDelegateCall(
        address _target,
        uint256 _maxFee
    ) external;

    function getRelayContextByTarget(
        address _target
    ) external view returns (RelayContext memory);

    function gelato() external view returns (address);
}
