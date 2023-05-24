// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SponsoredCall} from "../types/CallTypes.sol";

interface IGelatoRelay1Balance {
    function sponsoredCall(
        SponsoredCall calldata _call,
        address _sponsor,
        address _feeToken,
        uint256 _oneBalanceChainId,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _correlationId
    ) external;

    function gelato() external view returns (address);
}
