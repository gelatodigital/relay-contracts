// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// No need to implement user-specific signature verification
// Only sponsor signature is verified in order to ensure integrity of fee payments
struct SponsoredCall {
    uint256 chainId;
    address target;
    bytes data;
    address sponsor;
    address feeToken;
    uint256 oneBalanceChainId;
}

// When the user pays for themselves, so only user signature verification required
struct UserAuthCall {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    address feeToken;
    uint256 oneBalanceChainId;
}

// Relay call with built-in support with signature verification on behalf of user and sponsor
// Both user and sponsor signatures are verified
// The sponsor pays for the relay call
struct SponsoredUserAuthCall {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    address sponsor;
    address feeToken;
    uint256 oneBalanceChainId;
}
