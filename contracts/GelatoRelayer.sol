// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {IOracleAggregator} from "./interfaces/IOracleAggregator.sol";
import {IGelatoRelayerExecutor} from "./interfaces/IGelatoRelayerExecutor.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GelatoRelayer {
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
    IGelatoRelayerExecutor public immutable gelatoRelayerExecutor;

    uint256 public relayerFeePct;
    mapping(address => uint256) private _relayerNonces;
    mapping(address => mapping(address => uint256)) private _userTokenBalances;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(
        address _gelato,
        address _oracleAggregator,
        address _gelatoRelayerExecutor,
        uint256 _relayerFeePct,
        string memory _version
    ) {
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
                address(this),
                bytes32(chainId)
            )
        );
        oracleAggregator = IOracleAggregator(_oracleAggregator);
        gelatoRelayerExecutor = IGelatoRelayerExecutor(_gelatoRelayerExecutor);
        relayerFeePct = _relayerFeePct;
    }

    function executeRequest(Request calldata req, bytes calldata signature)
        external
        onlyGelato
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
        uint256 credit;
        if (req.isSelfPayingTx) {
            credit = gelatoRelayerExecutor.execSelfPayingTx(
                startGas,
                req.gasLimit,
                relayerFeePct,
                req.from,
                req.paymentToken,
                req.targets,
                req.isTargetEIP2771Compliant,
                req.payloads
            );
        } else {
            credit = gelatoRelayerExecutor.execPrepaidTx(
                startGas,
                req.gasLimit,
                relayerFeePct,
                req.from,
                req.paymentToken,
                req.targets,
                req.isTargetEIP2771Compliant,
                req.payloads
            );
            _updateUserBalance(req.from, req.paymentToken, credit);
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

    function _updateUserBalance(
        address _user,
        address _token,
        uint256 credit
    ) private {
        uint256 userTokenBalance = _userTokenBalances[_user][_token];
        require(
            userTokenBalance >= credit,
            "GelatoRelayer.execute: Insuficient user balance"
        );
        _userTokenBalances[_user][_token] -= credit;
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
