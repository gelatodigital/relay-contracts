// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ICounter {
    function increment() external;

    function counter() external view returns (uint256);
}
