// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable ordering, func-name-mixedcase

struct Message {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
}

struct MessageFeeCollector {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
}

struct MessageRelayContext {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
    uint256 fee;
}

struct ExecWithSigs {
    bytes32 correlationId;
    Message msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsFeeCollector {
    bytes32 correlationId;
    MessageFeeCollector msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsRelayContext {
    bytes32 correlationId;
    MessageRelayContext msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

/// @dev includes the interfaces of all facets
interface IGelato {
    // ########## ExecWithSigsFacet #########
    function execWithSigs(
        ExecWithSigs calldata _data
    ) external returns (uint256 estimatedGasUsed);

    function execWithSigsFeeCollector(
        ExecWithSigsFeeCollector calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee);

    function execWithSigsRelayContext(
        ExecWithSigsRelayContext calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // ########## Ownership Facet #########

    function owner() external view returns (address owner_);

    // ########## SignerFacet #########

    function addExecutorSigners(address[] calldata _executorSigners) external;

    function addCheckerSigners(address[] calldata _checkerSigners) external;

    function feeCollector() external view returns (address);
}
