// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {CallWithConcurrentERC2771} from "../types/CallTypes.sol";

interface IGelatoRelay1BalanceConcurrentERC2771 {
    function sponsoredCallConcurrentERC2771(
        CallWithConcurrentERC2771 calldata _call,
        address _sponsor,
        address _feeToken,
        uint256 _oneBalanceChainId,
        bytes calldata _userSignature,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _correlationId
    ) external;
}
