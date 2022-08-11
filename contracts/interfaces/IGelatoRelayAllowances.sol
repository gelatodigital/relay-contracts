// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGelatoRelayAllowances {
    function transferFrom(
        address _feeToken,
        address _from,
        uint256 _amount
    ) external;

    function transferStuckTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;
}
