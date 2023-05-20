// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable func-name-mixedcase
interface IGelatoRelay1BalanceERC2771Base {
    function userNonce(address _user) external view returns (uint256);

    function gelato() external view returns (address);

    function SPONSORED_CALL_ERC2771_TYPEHASH() external pure returns (bytes32);
}
