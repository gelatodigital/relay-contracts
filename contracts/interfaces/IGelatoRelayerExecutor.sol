// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {IGelatoRelayerRequestTypes} from "./IGelatoRelayerRequestTypes.sol";

interface IGelatoRelayerExecutor is IGelatoRelayerRequestTypes {
    function execSelfPayingTx(
        uint256 _gasCost,
        uint256 _relayerFeePct,
        Request calldata _req
    ) external returns (uint256 gasDebitInCreditToken, uint256 excessCredit);

    function execPrepaidTx(
        uint256 _gasCost,
        uint256 _relayerFeePct,
        Request calldata _req
    ) external returns (uint256 gasDebitInCreditToken);
}
