// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct Request {
    address from;
    address[] targets;
    bytes[] payloads;
    address feeToken;
    uint256 feeTokenPriceInNative;
    uint256 nonce;
    uint256 chainId;
    uint256 deadline;
    bool isSelfPayingTx;
    bool isFlashbotsTx;
    bool[] isTargetEIP2771Compliant;
}
