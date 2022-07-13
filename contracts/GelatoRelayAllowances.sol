// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IGelato} from "./interfaces/IGelato.sol";
import {IGelatoRelayAllowances} from "./interfaces/IGelatoRelayAllowances.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Intermediate contract for Gelato Relay to pull due fees.
///         Sponsors should approve ERC20 allowances to this smart contract
contract GelatoRelayAllowances is
    IGelatoRelayAllowances,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    address public immutable gelato;
    address public immutable relayForwarderPullFee;
    address public immutable metaBoxPullFee;

    constructor(
        address _gelato,
        address _relayForwarderPullFee,
        address _metaBoxPullFee
    ) {
        gelato = _gelato;
        relayForwarderPullFee = _relayForwarderPullFee;
        metaBoxPullFee = _metaBoxPullFee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pullFeeFrom(
        address _feeToken,
        address _from,
        uint256 _amount
    ) external override nonReentrant whenNotPaused {
        require(
            msg.sender == relayForwarderPullFee || msg.sender == metaBoxPullFee,
            "Caller not allowed"
        );

        address feeCollector = IGelato(gelato).getFeeCollector();

        SafeERC20.safeTransferFrom(
            IERC20(_feeToken),
            _from,
            feeCollector,
            _amount
        );
    }

    function transfer(
        address _feeToken,
        address _from,
        uint256 _amount
    ) external override onlyOwner whenNotPaused {
        SafeERC20.safeTransferFrom(
            IERC20(_feeToken),
            _from,
            msg.sender,
            _amount
        );
    }
}
