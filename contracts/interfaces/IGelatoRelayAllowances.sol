// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IGelatoRelayAllowances {
    function transferFrom(
        address _feeToken,
        address _from,
        uint256 _amount
    ) external;
}
