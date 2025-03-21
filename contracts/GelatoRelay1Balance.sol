// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IGelatoRelay1Balance} from "./interfaces/IGelatoRelay1Balance.sol";
import {IGelato1Balance} from "./interfaces/IGelato1Balance.sol";
import {GelatoCallUtils} from "./lib/GelatoCallUtils.sol";
import {SponsoredCall} from "./types/CallTypes.sol";

/// @title  Gelato Relay contract
/// @notice This contract deals with synchronous payments and Gelato 1Balance payments
/// @dev    This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here
// solhint-disable-next-line max-states-count
contract GelatoRelay1Balance is IGelatoRelay1Balance, IGelato1Balance {
    using GelatoCallUtils for address;

    address public immutable gelato;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    /// @notice Relay call + One Balance payment - with sponsor authentication
    /// @dev    Payment is handled with off-chain accounting using Gelato's 1Balance system
    /// @param _call Relay call data packed into SponsoredCall struct
    /// @notice Oracle value for exchange rate between native tokens and fee token
    /// @param  _nativeToFeeTokenXRateNumerator Exchange rate numerator
    /// @param  _nativeToFeeTokenXRateDenominator Exchange rate denominator
    /// @param _correlationId Unique task identifier generated by gelato
    // solhint-disable-next-line function-max-lines
    function sponsoredCall(
        SponsoredCall calldata _call,
        address _sponsor,
        address _feeToken,
        uint256 _oneBalanceChainId,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _correlationId
    ) external onlyGelato {
        // CHECKS
        require(
            _call.chainId == block.chainid,
            "GelatoRelay.sponsoredCall:chainid"
        );

        // INTERACTIONS
        _call.target.revertingContractCallNoCopy(
            _call.data,
            "GelatoRelay.sponsoredCall:"
        );

        emit LogUseGelato1Balance(
            _sponsor,
            _call.target,
            _feeToken,
            _oneBalanceChainId,
            _nativeToFeeTokenXRateNumerator,
            _nativeToFeeTokenXRateDenominator,
            _correlationId
        );
    }
}
