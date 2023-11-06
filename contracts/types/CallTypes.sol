// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Sponsored relay call
struct SponsoredCall {
    uint256 chainId;
    address target;
    bytes data;
}

// Sponsored relay call without chainId
struct SponsoredCallV2 {
    address target;
    bytes data;
}

// Relay call with user signature verification for ERC 2771 compliance
struct CallWithERC2771 {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
}

// Concurrent relay call with user signature verification for ERC 2771 compliance
struct CallWithConcurrentERC2771 {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    bytes32 userSalt;
    uint256 userDeadline;
}

struct RelayContext {
    address feeToken;
    uint256 fee;
}
