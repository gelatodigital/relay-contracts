// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {GelatoBytes} from "./libraries/GelatoBytes.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GelatoRelayer {
    using GelatoBytes for bytes;

    struct Request {
        address from;
        address to;
        uint256 value;
        uint256 gasLimit;
        uint256 relayerNonce;
        uint256 chainId;
        uint256 deadline;
        address paymentToken;
        bool isToEIP2771Compliant;
        bool isFlashbotsTx;
        bytes payload;
    }

    address public immutable gelato;
    uint256 public immutable chainId;

    mapping(address => uint256) private _relayerNonces;

    constructor(address _gelato) {
        gelato = _gelato;
        uint256 _chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
    }

    function execute(Request calldata req, bytes calldata signature)
        external
        payable
    {
        require(msg.sender == gelato, "GelatoRelayer.execute: Only gelato");
        require(
            req.relayerNonce == getRelayerNonce(req.from),
            "GelatoRelayer.execute: Invalid relayer nonce"
        );
        _relayerNonces[req.from] += 1;
        _verifySignature(req, signature);
        require(
            req.chainId == chainId,
            "GelatoRelayer.execute: Invalid chainId"
        );
        require(
            // solhint-disable-next-line not-rely-on-time
            req.deadline == 0 || block.timestamp <= req.deadline,
            "GelatoRelayer.execute: Expired"
        );
        (bool success, bytes memory returnData) = req.to.call{
            gas: req.gasLimit,
            value: req.value
        }(req.payload);
        if (!success) returnData.revertWithError("GelatoRelayer.execute:");
    }

    function getRelayerNonce(address _from)
        public
        view
        returns (uint256 relayerNonce)
    {
        relayerNonce = _relayerNonces[_from];
    }

    function _verifySignature(Request calldata req, bytes calldata signature)
        private
        pure
    {
        bytes32 message = keccak256(
            abi.encodePacked("\x19\x01", keccak256(_abiEncodeRequest(req)))
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
            req.from,
            req.to,
            req.value,
            req.gasLimit,
            req.relayerNonce,
            req.chainId,
            req.deadline,
            req.isToEIP2771Compliant,
            req.isFlashbotsTx,
            req.payload
        );
    }
}
