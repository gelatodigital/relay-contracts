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

contract GelatoRelayerExecutor is IGelatoRelayerExecutor, ReentrancyGuard {
    using GelatoBytes for bytes;
    using GelatoString for string;

    struct Request {
        address from;
        address[] targets;
        uint256 gasLimit;
        uint256 relayerNonce;
        uint256 chainId;
        uint256 deadline;
        address paymentToken;
        bool[] isTargetEIP2771Compliant;
        bool isSelfPayingTx;
        bool isFlashbotsTx;
        bytes[] payloads;
    }

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
        uint256 _gasLimit,
        uint256 _relayerFeePct,
        address _from,
        address _paymentToken,
        address[] calldata _targets,
        bool[] calldata _isTargetEIP2771Compliant,
        bytes[] calldata _payloads
    )
        external
        override
        onlyGelatoRelayer
        nonReentrant
        returns (uint256 credit)
    {
        uint256 preBalance = getBalance(_paymentToken, gelatoRelayer);
        _multiCall(_from, _targets, _isTargetEIP2771Compliant, _payloads);
        uint256 postBalance = getBalance(_paymentToken, gelatoRelayer);
        require(
            postBalance > preBalance,
            "GelatoRelayer.execute: insufficient paymentToken balance"
        );
        unchecked {
            credit = postBalance - preBalance;
        }
        uint256 gasDebitInNativeToken = _getGasDebitInNativeToken(
            _startGas,
            _gasLimit,
            _relayerFeePct
        );
        uint256 gasDebitInCreditToken = _paymentToken == NATIVE_TOKEN
            ? gasDebitInNativeToken
            : _getGasDebitInCreditToken(_paymentToken, gasDebitInNativeToken);
        require(
            credit >= gasDebitInCreditToken,
            "GelatoRelayer.execute: Insufficient payment"
        );
    }

    function execPrepaidTx(
        uint256 _startGas,
        uint256 _gasLimit,
        uint256 _relayerFeePct,
        address _from,
        address _paymentToken,
        address[] calldata _targets,
        bool[] calldata _isTargetEIP2771Compliant,
        bytes[] calldata _payloads
    )
        external
        override
        onlyGelatoRelayer
        nonReentrant
        returns (uint256 gasDebitInCreditToken)
    {
        _multiCall(_from, _targets, _isTargetEIP2771Compliant, _payloads);
        uint256 gasDebitInNativeToken = _getGasDebitInNativeToken(
            _startGas,
            _gasLimit,
            _relayerFeePct
        );
        gasDebitInCreditToken = _paymentToken == NATIVE_TOKEN
            ? gasDebitInNativeToken
            : _getGasDebitInCreditToken(_paymentToken, gasDebitInNativeToken);
        /*uint256 userTokenBalance = _userTokenBalances[_req.from][
            _req.paymentToken
        ];
        require(
            userTokenBalance >= gasDebitInCreditToken,
            "GelatoRelayer.execute: Insuficient user balance"
        );
        _userTokenBalances[_req.from][
            _req.paymentToken
        ] -= gasDebitInCreditToken;*/
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
            "GelatoRelayer.execute: Array length mismatch"
        );
        for (uint256 i; i < _targets.length; i++) {
            (bool success, bytes memory returnData) = _targets[i].call(
                _isTargetEIP2771Compliant[i]
                    ? abi.encodePacked(_payloads[i], _from)
                    : _payloads[i]
            );
            if (!success) returnData.revertWithError("GelatoRelayer.execute:");
        }
    }

    function _getGasDebitInNativeToken(
        uint256 _startGas,
        uint256 _gasLimit,
        uint256 _relayerFeePct
    ) private view returns (uint256 gasDebitInNativeToken) {
        uint256 gasCost = _startGas + DIAMOND_CALL_OVERHEAD - gasleft();
        require(
            gasCost <= _gasLimit,
            "GelatoRelayer.execute: gasLimit exceeded"
        );
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
                "ExecFacet.exec:  _creditToken not on OracleAggregator"
            );
            gasDebitInCreditToken = gasDebitInCreditToken_;
        } catch Error(string memory err) {
            err.revertWithInfo("ExecFacet.exec: OracleAggregator:");
        } catch {
            revert("ExecFacet.exec: OracleAggregator: unknown error");
        }
    }
}
