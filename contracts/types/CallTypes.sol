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
    uint256 sponsorSalt;
    PaymentType paymentType;
    address feeToken;
    uint256 oneBalanceChainId;
    uint256 maxFee;
}

// When the user pays for themselves, so only user signature verification required
struct UserAuthCall {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    PaymentType paymentType;
    address feeToken;
    uint256 oneBalanceChainId;
    uint256 maxFee;
}

// Relay call with built-in support with signature verification on behalf of user and sponsor
// Both user and sponsor signatures are verified
// The sponsor pays for the relay call
struct UserSponsorAuthCall {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    address sponsor; // could be same as user
    uint256 sponsorSalt;
    PaymentType paymentType;
    address feeToken;
    uint256 oneBalanceChainId;
    uint256 maxFee;
}
