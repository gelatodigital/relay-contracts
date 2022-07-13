// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IGelatoRelayAllowances} from "./interfaces/IGelatoRelayAllowances.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Intermediate contract for Gelato Relay to pull due fees.
///         Sponsors should approve ERC20 allowances to this smart contract
contract GelatoRelayAllowances is IGelatoRelayAllowances, ReentrancyGuard {
    address public immutable relayForwarderPullFee;
    address public immutable metaBoxPullFee;

    constructor(address _relayForwarderPullFee, address _metaBoxPullFee) {
        relayForwarderPullFee = _relayForwarderPullFee;
        metaBoxPullFee = _metaBoxPullFee;
    }

    function pullFeeFrom(
        address _feeToken,
        address _from,
        address _to,
        uint256 _amount
    ) external override nonReentrant {
        require(
            msg.sender == relayForwarderPullFee || msg.sender == metaBoxPullFee,
            "Caller not allowed"
        );

        SafeERC20.safeTransferFrom(IERC20(_feeToken), _from, _to, _amount);
    }
}
