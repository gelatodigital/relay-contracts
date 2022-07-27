// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PaymentType} from "./PaymentTypes.sol";

// No need to implement user-specific signature verification
// Only sponsor signature is verified in order to ensure integrity of fee payments
struct SponsorAuthCall {
    uint256 chainId;
    address target;
    bytes data;
    address sponsor;
    uint256 sponsorChainId;
    uint256 sponsorNonce;
    address feeToken;
    PaymentType paymentType;
    uint256 maxFee;
}

// Relay request with built-in support with signature verification on behalf of user
// In case a sponsor (other than user) wants to pay for the tx,
// we will also need to verify sponsor's signature
struct UserSponsorAuthCall {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    address sponsor; // could be same as user
    uint256 sponsorChainId;
    uint256 sponsorNonce;
    PaymentType paymentType;
    address feeToken;
    uint256 maxFee;
}
