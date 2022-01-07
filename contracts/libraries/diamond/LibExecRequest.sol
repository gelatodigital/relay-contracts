// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Request} from "../../structs/RequestTypes.sol";
import {getBalance} from "../../functions/TokenUtils.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {
    IGelatoRelayerTreasury
} from "../../interfaces/IGelatoRelayerTreasury.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibExecRequest {
    using GelatoBytes for bytes;

    struct ExecRequestStorage {
        mapping(address => uint256) nonces;
    }

    bytes32 private constant _EXEC_REQUEST_STORAGE_POSITION =
        keccak256("gelatorelayer.diamond.exec.request.storage");

    bytes32 public constant REQUEST_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Request(address from,address[] targets,bytes[] payloads,address feeToken,uint256 feeTokenPriceInNative,uint256 nonce,uint256 chainId,uint256 deadline,bool isSelfPayingTx,bool isFlashbotsTx,bool[] isTargetEIP2771Compliant)"
            )
        );

    function execSelfPayingTx(
        address _gelato,
        address _gelatoRelayerTreasury,
        Request calldata _req
    ) internal returns (uint256 credit) {
        require(
            IGelatoRelayerTreasury(_gelatoRelayerTreasury).isPaymentToken(
                _req.feeToken
            ),
            "Invalid feeToken"
        );

        uint256 preBalance = getBalance(_req.feeToken, _gelato);
        _multiCall(
            _gelatoRelayerTreasury,
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 postBalance = getBalance(_req.feeToken, _gelato);

        credit = postBalance - preBalance;
    }

    function execPrepaidTx(
        address _gelatoRelayerTreasury,
        Request calldata _req
    ) internal {
        _multiCall(
            _gelatoRelayerTreasury,
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
    }

    function verifyAndIncrementNonce(uint256 _nonce, address _from) internal {
        ExecRequestStorage storage es = _execRequestStorage();
        require(_nonce == es.nonces[_from], "Invalid nonce");

        es.nonces[_from] += 1;
    }

    function verifyDeadline(uint256 _deadline) internal view {
        require(
            // solhint-disable-next-line not-rely-on-time
            _deadline == 0 || block.timestamp <= _deadline,
            "Expired"
        );
    }

    function verifyChainId(uint256 _chainId) internal view {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        require(_chainId == chainId, "Invalid Chain Id");
    }

    function verifyGasCost(
        uint256 _gasCost,
        uint256 _startGas,
        uint256 _diamondCallOverhead
    ) internal view {
        uint256 gasCost = _startGas + _diamondCallOverhead - gasleft();
        require(_gasCost <= gasCost, "Executor overcharged in Gas Cost");
    }

    function verifySignature(
        bytes32 domainSeparator,
        Request calldata req,
        bytes calldata signature
    ) internal pure {
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

    function _multiCall(
        address _treasury,
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
                _targets[i] != _treasury,
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

    function _execRequestStorage()
        private
        pure
        returns (ExecRequestStorage storage es)
    {
        bytes32 position = _EXEC_REQUEST_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            es.slot := position
        }
    }

    function _abiEncodeRequest(Request calldata _req)
        private
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            REQUEST_TYPEHASH,
            _req.from,
            keccak256(abi.encode(_req.targets)),
            keccak256(abi.encode(_req.payloads)),
            _req.feeToken,
            _req.feeTokenPriceInNative,
            _req.nonce,
            _req.chainId,
            _req.deadline,
            _req.isSelfPayingTx,
            _req.isFlashbotsTx,
            keccak256(abi.encode(_req.isTargetEIP2771Compliant))
        );
    }
}
