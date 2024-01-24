// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IGelatoRelay1BalanceV2 {
    function sponsoredCallV2(
        address _target,
        bytes calldata _data,
        bytes32 _correlationId,
        bytes32 _r,
        bytes32 _vs
    ) external;
}
