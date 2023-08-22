// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable func-name-mixedcase
interface IGelatoRelay1BalanceConcurrentERC2771Base {
    function hashUsed(bytes32 _hash) external view returns (bool);

    function gelato() external view returns (address);

    function SPONSORED_CALL_CONCURRENT_ERC2771_TYPEHASH()
        external
        pure
        returns (bytes32);
}
