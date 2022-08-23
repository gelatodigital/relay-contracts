// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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

/// @notice Intermediate contract for Gelato Relay to transferFrom
/// @dev    Sponsors should approve ERC20 allowances to this smart contract
contract GelatoRelayAllowances is
    IGelatoRelayAllowances,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    address public immutable gelato;
    address public immutable gelatoRelayWithTransferFrom;

    modifier onlyGelatoRelayWithTransferFrom() {
        require(
            msg.sender == gelatoRelayWithTransferFrom,
            "GelatoRelayAllowances.onlyGelatoRelayWithTransferFrom"
        );
        _;
    }

    constructor(address _gelato, address _gelatoRelayWithTransferFrom) {
        gelato = _gelato;
        gelatoRelayWithTransferFrom = _gelatoRelayWithTransferFrom;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transferFrom(
        address _feeToken,
        address _from,
        uint256 _amount
    )
        external
        override
        nonReentrant
        onlyGelatoRelayWithTransferFrom
        whenNotPaused
    {
        SafeERC20.safeTransferFrom(
            IERC20(_feeToken),
            _from,
            IGelato(gelato).getFeeCollector(),
            _amount
        );
    }

    function transferStuckTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        _token.safeTransfer(_to, _amount);
    }
}
