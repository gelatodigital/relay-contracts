// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {getBalance} from "./functions/TokenUtils.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {GelatoBytes} from "./libraries/GelatoBytes.sol";
import {GelatoString} from "./libraries/GelatoString.sol";
import {IOracleAggregator} from "./interfaces/IOracleAggregator.sol";
import {IGelatoRelayerExecutor} from "./interfaces/IGelatoRelayerExecutor.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GelatoRelayerExecutor is ReentrancyGuard, IGelatoRelayerExecutor {
    using GelatoBytes for bytes;
    using GelatoString for string;

    uint256 public constant DIAMOND_CALL_OVERHEAD = 21000;

    address public immutable gelatoRelayer;
    IOracleAggregator public immutable oracleAggregator;

    modifier onlyGelatoRelayer() {
        require(msg.sender == gelatoRelayer, "Only gelatoRelayer");
        _;
    }

    constructor(address _gelatoRelayer, address _oracleAggregator)
        ReentrancyGuard()
    {
        gelatoRelayer = _gelatoRelayer;
        oracleAggregator = IOracleAggregator(_oracleAggregator);
    }

    function execSelfPayingTx(
        uint256 _startGas,
        uint256 _relayerFeePct,
        Request calldata _req
    )
        external
        override
        onlyGelatoRelayer
        nonReentrant
        returns (uint256 gasDebitInCreditToken, uint256 excessCredit)
    {
        uint256 preBalance = getBalance(_req.paymentToken, gelatoRelayer);
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 postBalance = getBalance(_req.paymentToken, gelatoRelayer);
        require(postBalance > preBalance, "Insufficient paymentToken balance");
        uint256 credit;
        unchecked {
            credit = postBalance - preBalance;
        }
        uint256 gasDebitInNativeToken = _getGasDebitInNativeToken(
            _startGas,
            _req.gasLimit,
            _relayerFeePct
        );
        gasDebitInCreditToken = _req.paymentToken == NATIVE_TOKEN
            ? gasDebitInNativeToken
            : _getGasDebitInCreditToken(
                _req.paymentToken,
                gasDebitInNativeToken
            );
        require(credit >= gasDebitInCreditToken, "Insufficient payment");
        excessCredit = credit - gasDebitInCreditToken;
    }

    function execPrepaidTx(
        uint256 _startGas,
        uint256 _relayerFeePct,
        Request calldata _req
    )
        external
        override
        onlyGelatoRelayer
        nonReentrant
        returns (uint256 gasDebitInCreditToken)
    {
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 gasDebitInNativeToken = _getGasDebitInNativeToken(
            _startGas,
            _req.gasLimit,
            _relayerFeePct
        );
        gasDebitInCreditToken = _req.paymentToken == NATIVE_TOKEN
            ? gasDebitInNativeToken
            : _getGasDebitInCreditToken(
                _req.paymentToken,
                gasDebitInNativeToken
            );
    }

    function _multiCall(
        address _from,
        address[] calldata _targets,
        bool[] calldata _isTargetEIP2771Compliant,
        bytes[] calldata _payloads
    ) private {
        require(
            _targets.length == _payloads.length &&
                _targets.length == _isTargetEIP2771Compliant.length,
            "Array length mismatch"
        );
        for (uint256 i; i < _targets.length; i++) {
            (bool success, bytes memory returnData) = _targets[i].call(
                _isTargetEIP2771Compliant[i]
                    ? abi.encodePacked(_payloads[i], _from)
                    : _payloads[i]
            );
            if (!success)
                returnData.revertWithError("GelatoRelayerExecutor._multiCall:");
        }
    }

    function _getGasDebitInNativeToken(
        uint256 _startGas,
        uint256 _gasLimit,
        uint256 _relayerFeePct
    ) private view returns (uint256 gasDebitInNativeToken) {
        uint256 gasCost = _startGas + DIAMOND_CALL_OVERHEAD - gasleft();
        require(gasCost <= _gasLimit, "gasLimit exceeded");
        gasDebitInNativeToken =
            (gasCost * tx.gasprice * (100 + _relayerFeePct)) /
            100;
    }

    function _getGasDebitInCreditToken(
        address _creditToken,
        uint256 _gasDebitInNativeToken
    ) private view returns (uint256 gasDebitInCreditToken) {
        try
            oracleAggregator.getExpectedReturnAmount(
                _gasDebitInNativeToken,
                NATIVE_TOKEN,
                _creditToken
            )
        returns (uint256 gasDebitInCreditToken_, uint256) {
            require(
                gasDebitInCreditToken_ != 0,
                "_creditToken not on OracleAggregator"
            );
            gasDebitInCreditToken = gasDebitInCreditToken_;
        } catch Error(string memory err) {
            err.revertWithInfo("OracleAggregator:");
        } catch {
            revert("OracleAggregator: unknown error");
        }
    }
}
