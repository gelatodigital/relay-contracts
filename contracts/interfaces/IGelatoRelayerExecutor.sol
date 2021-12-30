// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGelatoRelayerExecutor {
    function execSelfPayingTx(
        uint256 _startGas,
        uint256 _gasLimit,
        uint256 _relayerFeePct,
        address _from,
        address _paymentToken,
        address[] calldata _targets,
        bool[] calldata _isTargetEIP2771Compliant,
        bytes[] calldata _payloads
    ) external returns (uint256 credit);

    function execPrepaidTx(
        uint256 _startGas,
        uint256 _gasLimit,
        uint256 _relayerFeePct,
        address _from,
        address _paymentToken,
        address[] calldata _targets,
        bool[] calldata _isTargetEIP2771Compliant,
        bytes[] calldata _payloads
    ) external returns (uint256 gasDebitInCreditToken);
}
