// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {BFacetOwner} from "./base/BFacetOwner.sol";
import {LibTransfer} from "../libraries/diamond/LibTransfer.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferFacet is BFacetOwner {
    function withdrawTokens(
        address[] calldata _tokens,
        address[] calldata _receivers
    ) external onlyOwner {
        require(_tokens.length == _receivers.length, "Array length mismatch");

        for (uint256 i; i < _tokens.length; i++) {
            LibTransfer.handleTransfer(
                _tokens[i],
                _receivers[i],
                IERC20(_tokens[i]).balanceOf(address(this))
            );
        }
    }
}
