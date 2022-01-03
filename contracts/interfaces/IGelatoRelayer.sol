// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {IGelatoRelayerRequestTypes} from "./IGelatoRelayerRequestTypes.sol";

interface IGelatoRelayer is IGelatoRelayerRequestTypes {
    function executeRequest(
        uint256 _gasCost,
        Request calldata _req,
        bytes calldata _signature
    ) external;

    function setRelayerFeePct(uint256 _relayerFeePct) external;

    function relayerNonce(address _from) external view returns (uint256);
}
