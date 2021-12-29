// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {GelatoBytes} from "./libraries/GelatoBytes.sol";
import {GelatoString} from "./libraries/GelatoString.sol";
import {getBalance} from "./functions/TokenUtils.sol";
import {IOracleAggregator} from "./interfaces/IOracleAggregator.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GelatoRelayer is ReentrancyGuard {
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

    bytes32 public constant REQUEST_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Request(address from,address[] targets,uint256 gasLimit,uint256 relayerNonce,uint256 chainId,uint256 deadline,uint256 paymentToken,bool[] isTargetEIP2771Compliant,bool isSelfPayingTx,bool isFlashbotsTx,bytes[] payloads)"
            )
        );
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)";
    uint256 public constant DIAMOND_CALL_OVERHEAD = 21000;

    address public immutable gelato;
    uint256 public immutable chainId;
    bytes32 public immutable domainSeparator;
    IOracleAggregator public immutable oracleAggregator;

    uint256 public relayFeePct;
    mapping(address => uint256) private _relayerNonces;
    mapping(address => mapping(address => uint256)) private _userTokenBalances;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(
        address _gelato,
        string memory version,
        address _oracleAggregator,
        uint256 _relayFeePct
    ) ReentrancyGuard() {
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
                keccak256(bytes(version)),
                address(this),
                bytes32(chainId)
            )
        );
        oracleAggregator = IOracleAggregator(_oracleAggregator);
        relayFeePct = _relayFeePct;
    }

    function executeRequest(Request calldata req, bytes calldata signature)
        external
        onlyGelato
        nonReentrant
    {
        uint256 startGas = gasleft();
        require(
            // solhint-disable-next-line not-rely-on-time
            req.deadline == 0 || block.timestamp <= req.deadline,
            "GelatoRelayer.execute: Expired"
        );
        _verifyAndIncrementNonce(req.relayerNonce, req.from);
        _verifySignature(req, signature);
        require(
            req.chainId == chainId,
            "GelatoRelayer.execute: Invalid chainId"
        );
        if (req.isSelfPayingTx) {
            _execSelfPayingTx(startGas, req);
        } else {
            _execPrepaidTx(startGas, req);
        }
    }

    function getRelayerNonce(address _from)
        external
        view
        returns (uint256 relayerNonce)
    {
        relayerNonce = _relayerNonces[_from];
    }

    function _verifyAndIncrementNonce(uint256 _relayerNonce, address _from)
        private
    {
        require(
            _relayerNonce == _relayerNonces[_from],
            "GelatoRelayer.execute: Invalid relayer nonce"
        );
        _relayerNonces[_from] += 1;
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

    function _execSelfPayingTx(uint256 _startGas, Request calldata _req)
        private
    {
        uint256 preBalance = getBalance(_req.paymentToken, address(this));
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 postBalance = getBalance(_req.paymentToken, address(this));
        require(
            postBalance >= preBalance,
            "GelatoRelayer.execute: paymentToken balance decreased"
        );
        uint256 credit;
        unchecked {
            credit = postBalance - preBalance;
        }
        uint256 gasCost = _startGas + DIAMOND_CALL_OVERHEAD - gasleft();
        require(
            gasCost <= _req.gasLimit,
            "GelatoRelayer.execute: gasLimit exceeded"
        );
        uint256 gasDebitInNativeToken = (gasCost *
            tx.gasprice *
            (100 + relayFeePct)) / 100;
        uint256 gasDebitInCreditToken = _req.paymentToken == NATIVE_TOKEN
            ? gasDebitInNativeToken
            : _getGasDebitInCreditToken(
                _req.paymentToken,
                gasDebitInNativeToken
            );
        require(
            credit >= gasDebitInCreditToken,
            "GelatoRelayer.execute: Insufficient payment"
        );
    }

    function _execPrepaidTx(uint256 _startGas, Request calldata _req) private {
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 gasCost = _startGas + DIAMOND_CALL_OVERHEAD - gasleft();
        require(
            gasCost <= _req.gasLimit,
            "GelatoRelayer.execute: gasLimit exceeded"
        );
        uint256 gasDebitInNativeToken = (gasCost *
            tx.gasprice *
            (100 + relayFeePct)) / 100;
        uint256 gasDebitInCreditToken = _req.paymentToken == NATIVE_TOKEN
            ? gasDebitInNativeToken
            : _getGasDebitInCreditToken(
                _req.paymentToken,
                gasDebitInNativeToken
            );
        uint256 userTokenBalance = _userTokenBalances[_req.from][
            _req.paymentToken
        ];
        require(
            userTokenBalance >= gasDebitInCreditToken,
            "GelatoRelayer.execute: Insuficient user balance"
        );
        _userTokenBalances[_req.from][
            _req.paymentToken
        ] -= gasDebitInCreditToken;
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
        require(
            from == req.from,
            "GelatoRelayer._verifySignature: Invalid signature"
        );
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
