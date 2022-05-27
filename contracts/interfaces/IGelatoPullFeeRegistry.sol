// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGelatoPullFeeRegistry {
    function pullFeeFrom(
        address _feeToken,
        address _from,
        address _to,
        uint256 _amount
    ) external;
}
