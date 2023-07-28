// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable func-name-mixedcase
interface IGelatoRelayConcurrentERC2771Base {
    function hashUsed(bytes32 _hash) external view returns (bool);

    function gelato() external view returns (address);

    function CALL_WITH_SYNC_FEE_CONCURRENT_ERC2771_TYPEHASH()
        external
        pure
        returns (bytes32);
}
