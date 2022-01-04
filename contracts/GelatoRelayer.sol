// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {getBalance} from "./functions/TokenUtils.sol";
import {GelatoBytes} from "./libraries/GelatoBytes.sol";
import {GelatoString} from "./libraries/GelatoString.sol";
import {IGelatoRelayer} from "./interfaces/IGelatoRelayer.sol";
import {IOracleAggregator} from "./interfaces/IOracleAggregator.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GelatoRelayer is Initializable, IGelatoRelayer {
    using GelatoBytes for bytes;
    using GelatoString for string;

    bytes32 public constant REQUEST_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Request(address from,address[] targets,uint256 gasLimit,uint256 relayerNonce,uint256 chainId,uint256 deadline,uint256 paymentToken,bool[] isTargetEIP2771Compliant,bool isSelfPayingTx,bool isFlashbotsTx,bytes[] payloads)"
            )
        );
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    uint256 public constant DIAMOND_CALL_OVERHEAD = 32000;

    address public immutable owner;
    address public immutable gelato;
    uint256 public immutable chainId;
    bytes32 public immutable domainSeparator;
    IOracleAggregator public immutable oracleAggregator;
    ITreasury public immutable treasury;

    uint256 public relayerFeePct;
    mapping(address => uint256) private _relayerNonces;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(
        address _owner,
        address _gelato,
        address _oracleAggregator,
        address _treasury,
        string memory _version
    ) {
        owner = _owner;
        gelato = _gelato;
        uint256 _chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
        domainSeparator = keccak256(
            abi.encode(
                keccak256(bytes(EIP712_DOMAIN_TYPE)),
                keccak256(bytes("GelatoRelayer")),
                keccak256(bytes(_version)),
                bytes32(chainId),
                address(this)
            )
        );
        oracleAggregator = IOracleAggregator(_oracleAggregator);
        treasury = ITreasury(_treasury);
    }

    function initialize(uint256 _relayerFeePct) external initializer {
        relayerFeePct = _relayerFeePct;
    }

    function executeRequest(
        uint256 _gasCost,
        Request calldata _req,
        bytes calldata _signature
    ) external override onlyGelato {
        uint256 startGas = gasleft();
        _verifyDeadline(_req.deadline);
        _verifyGasLimit(_gasCost, _req.gasLimit);
        _verifyChainId(_req.chainId);
        _verifyAndIncrementNonce(_req.relayerNonce, _req.from);
        _verifySignature(_req, _signature);
        uint256 credit;
        if (_req.isSelfPayingTx) {
            uint256 excessCredit;
            (credit, excessCredit) = _execSelfPayingTx(_gasCost, _req);
            if (excessCredit > 0) {
                treasury.incrementUserBalance(
                    _req.from,
                    _req.paymentToken,
                    excessCredit
                );
                credit = credit - excessCredit;
            }
            if (credit > 0) _transferHandler(_req.paymentToken, gelato, credit);
        } else {
            credit = _execPrepaidTx(_gasCost, _req);
            if (credit > 0)
                treasury.creditUserPayment(
                    _req.from,
                    _req.paymentToken,
                    credit
                );
        }
        _verifyGasCost(startGas, _gasCost);
    }

    function rescueTokens(
        address[] calldata _tokens,
        address[] calldata _receivers
    ) external override onlyOwner {
        require(_tokens.length == _receivers.length, "Array length mismatch");
        for (uint256 i; i < _tokens.length; i++) {
            _transferHandler(
                _tokens[i],
                _receivers[i],
                IERC20(_tokens[i]).balanceOf(address(this))
            );
        }
    }

    function setRelayerFeePct(uint256 _relayerFeePct)
        external
        override
        onlyOwner
    {
        require(_relayerFeePct <= 100, "Invalid percentage");
        relayerFeePct = _relayerFeePct;
    }

    function relayerNonce(address _from)
        external
        view
        override
        returns (uint256)
    {
        return _relayerNonces[_from];
    }

    function _verifyAndIncrementNonce(uint256 _relayerNonce, address _from)
        private
    {
        require(
            _relayerNonce == _relayerNonces[_from],
            "Invalid relayer nonce"
        );
        _relayerNonces[_from] += 1;
    }

    function _transferHandler(
        address _paymentToken,
        address _receiver,
        uint256 _amount
    ) private {
        if (_paymentToken == NATIVE_TOKEN) {
            (bool success, ) = _receiver.call{value: _amount}("");
            require(success, "ETH payment failed");
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            SafeERC20.safeTransfer(paymentToken, _receiver, _amount);
        }
    }

    function _execSelfPayingTx(uint256 _gasCost, Request calldata _req)
        private
        returns (uint256 gasDebitInCreditToken, uint256 excessCredit)
    {
        require(
            treasury.isPaymentToken(_req.paymentToken),
            "Invalid paymentToken"
        );
        // Q: Requiring direct payment to diamond would save a lot of gas,
        // but would it hurt UX?
        uint256 preBalance = getBalance(_req.paymentToken, address(this));
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 postBalance = getBalance(_req.paymentToken, address(this));
        require(postBalance > preBalance, "Insufficient paymentToken balance");
        uint256 credit;
        unchecked {
            credit = postBalance - preBalance;
        }
        uint256 gasDebitInNativeToken = _getGasDebitInNativeToken(_gasCost);
        gasDebitInCreditToken = _req.paymentToken == NATIVE_TOKEN
            ? gasDebitInNativeToken
            : _getGasDebitInCreditToken(
                _req.paymentToken,
                gasDebitInNativeToken
            );
        require(credit >= gasDebitInCreditToken, "Insufficient payment");
        excessCredit = credit - gasDebitInCreditToken;
    }

    function _execPrepaidTx(uint256 _gasCost, Request calldata _req)
        private
        returns (uint256 gasDebitInCreditToken)
    {
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 gasDebitInNativeToken = _getGasDebitInNativeToken(_gasCost);
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
            require(
                _targets[i] != address(treasury),
                "Unsafe external call to Treasury"
            );
            (bool success, bytes memory returnData) = _targets[i].call(
                _isTargetEIP2771Compliant[i]
                    ? abi.encodePacked(_payloads[i], _from)
                    : _payloads[i]
            );
            if (!success)
                returnData.revertWithError("GelatoRelayerExecutor._multiCall:");
        }
    }

    function _getGasDebitInNativeToken(uint256 _gasCost)
        private
        view
        returns (uint256 gasDebitInNativeToken)
    {
        gasDebitInNativeToken =
            (_gasCost * tx.gasprice * (100 + relayerFeePct)) /
            100;
    }

    function _getGasDebitInNativeTokenEIP1559(uint256 _gasCost)
        private
        view
        returns (uint256 gasDebitInNativeToken)
    {
        uint256 _gasDebitBase = block.basefee * _gasCost;
        uint256 _priorityFee = tx.gasprice - block.basefee;
        gasDebitInNativeToken =
            _gasDebitBase +
            (_gasCost * _priorityFee * (100 + relayerFeePct)) /
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

    function _verifyDeadline(uint256 _deadline) private view {
        require(
            // solhint-disable-next-line not-rely-on-time
            _deadline == 0 || block.timestamp <= _deadline,
            "Expired"
        );
    }

    function _verifyChainId(uint256 _chainId) private view {
        require(_chainId == chainId, "Invalid Chain Id");
    }

    function _verifySignature(Request calldata req, bytes calldata signature)
        private
        view
    {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(_abiEncodeRequest(req))
            )
        );
        address from = ECDSA.recover(message, signature);
        require(from == req.from, "Invalid signature");
    }

    function _verifyGasCost(uint256 _startGas, uint256 _gasCost) private view {
        uint256 maxGasCost = DIAMOND_CALL_OVERHEAD + gasleft() - _startGas;
        require(_gasCost <= maxGasCost, "Executor overcharged in Gas Cost");
    }

    function _verifyGasLimit(uint256 _gasCost, uint256 _gasLimit) private pure {
        require(_gasCost <= _gasLimit, "Gas Cost > Gas Limit");
    }

    function _abiEncodeRequest(Request calldata req)
        private
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            REQUEST_TYPEHASH,
            req.from,
            req.targets,
            req.gasLimit,
            req.relayerNonce,
            req.chainId,
            req.deadline,
            req.isTargetEIP2771Compliant,
            req.isSelfPayingTx,
            req.isFlashbotsTx,
            keccak256(abi.encode(req.payloads))
        );
    }
}
