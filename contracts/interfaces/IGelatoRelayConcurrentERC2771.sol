// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {CallWithConcurrentERC2771} from "../types/CallTypes.sol";

interface IGelatoRelayConcurrentERC2771 {
    event LogCallWithSyncFeeConcurrentERC2771(
        address indexed target,
        bytes32 indexed correlationId
    );

    function callWithSyncFeeConcurrentERC2771(
        CallWithConcurrentERC2771 calldata _call,
        address _feeToken,
        bytes calldata _userSignature,
        bool _isRelayContext,
        bytes32 _correlationId
    ) external;
}
