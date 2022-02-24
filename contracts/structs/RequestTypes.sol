// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct Request {
    uint256 chainId;
    address target;
    bytes data;
    address feeToken;
    address user;
    address sponsor; // could be same as user
    uint256 nonce;
    uint256 deadline;
    bool isEIP2771;
}
