// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Request} from "../structs/RequestTypes.sol";

interface IGelatoRelayer {
    function executeRequest(
        uint256 _gasCost,
        uint256 _gelatoFee,
        Request calldata _req,
        bytes calldata _signature
    ) external returns (uint256 creditInNativeToken, uint256 expectedCost);

    function withdrawTokens(
        address[] calldata _tokens,
        address[] calldata _receivers
    ) external;
}
