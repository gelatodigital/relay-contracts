// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

function getBalance(address token, address user) view returns (uint256) {
    return token == NATIVE_TOKEN ? user.balance : IERC20(token).balanceOf(user);
}
