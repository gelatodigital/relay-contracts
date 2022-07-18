// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// solhint-disable-next-line
function _transfer(
    address _token,
    address _to,
    uint256 _amount
) {
    if (_amount == 0) return;

    if (_token == NATIVE_TOKEN) {
        Address.sendValue(payable(_to), _amount);
    } else {
        SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
    }
}

// solhint-disable-next-line
function _getBalance(address token, address user) view returns (uint256) {
    return token == NATIVE_TOKEN ? user.balance : IERC20(token).balanceOf(user);
}
