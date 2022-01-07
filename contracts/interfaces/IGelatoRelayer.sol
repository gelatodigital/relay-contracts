// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Request} from "../structs/RequestTypes.sol";

interface IGelatoRelayer {
    function executeRequest(
        uint256 _gasCost,
        Request calldata _req,
        bytes calldata _signature
    ) external returns (uint256 credit);

    function withdrawTokens(
        address[] calldata _tokens,
        address[] calldata _receivers
    ) external;
}
