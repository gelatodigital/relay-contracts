// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {PaymentType} from "./PaymentTypes.sol";

// No need to implement user-specific signature verification
// Only sponsor signature is verified in order to ensure integrity of fee payments
struct SponsorAuthCallWith1Balance {
    uint256 chainId;
    address target;
    bytes data;
    address sponsor;
    uint256 sponsorSalt;
    PaymentType paymentType;
    address feeToken;
    uint256 oneBalanceChainId;
}

// When the user pays for themselves, so only user signature verification required
struct UserAuthCallWith1Balance {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    PaymentType paymentType;
    address feeToken;
    uint256 oneBalanceChainId;
}

// Relay call with built-in support with signature verification on behalf of user and sponsor
// Both user and sponsor signatures are verified
// The sponsor pays for the relay call
struct UserSponsorAuthCallWith1Balance {
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
}
// No need to implement user-specific signature verification
// Only sponsor signature is verified in order to ensure integrity of fee payments
struct SponsorAuthCallWithTransferFrom {
    uint256 chainId;
    address target;
    bytes data;
    address sponsor;
    uint256 sponsorSalt;
    PaymentType paymentType;
    address feeToken;
    uint256 maxFee;
}

// When the user pays for themselves, so only user signature verification required
struct UserAuthCallWithTransferFrom {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    PaymentType paymentType;
    address feeToken;
    uint256 maxFee;
}

// Relay call with built-in support with signature verification on behalf of user and sponsor
// Both user and sponsor signatures are verified
// The sponsor pays for the relay call
struct UserSponsorAuthCallWithTransferFrom {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
    address sponsor;
    uint256 sponsorSalt;
    PaymentType paymentType;
    address feeToken;
    uint256 maxFee;
}
