// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGelatoRelayerRequestTypes {
    struct Request {
        address from;
        address[] targets;
        uint256 gasLimit;
        uint256 relayerNonce;
        uint256 chainId;
        uint256 deadline;
        address paymentToken;
        bool[] isTargetEIP2771Compliant;
        bool isSelfPayingTx;
        bool isFlashbotsTx;
        bytes[] payloads;
    }
}
