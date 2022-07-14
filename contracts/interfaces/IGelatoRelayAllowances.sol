// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGelatoRelayAllowances {
    function pullFeeFrom(
        address _feeToken,
        address _from,
        uint256 _amount
    ) external;

    function transfer(
        address _feeToken,
        address _from,
        address _to,
        uint256 _amount
    ) external;
}
