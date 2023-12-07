// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IGelato1Balance {
    event LogUseGelato1Balance(
        address indexed sponsor,
        address indexed target,
        address indexed feeToken,
        uint256 oneBalanceChainId,
        uint256 nativeToFeeTokenXRateNumerator,
        uint256 nativeToFeeTokenXRateDenominator,
        bytes32 correlationId
    );

    event LogUseGelato1BalanceV2(bytes32 correlationId, bytes32 r, bytes32 vs);
}
