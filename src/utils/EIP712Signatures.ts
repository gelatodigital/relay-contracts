/* eslint-disable @typescript-eslint/naming-convention */
import {
  computeAddress,
  keccak256,
  SigningKey,
  solidityPackedKeccak256,
  toUtf8Bytes,
  AbiCoder,
} from "ethers";
import {
  MessageStruct,
  MessageFeeCollectorStruct,
  MessageRelayContextStruct,
} from "../../typechain/contracts/interfaces/IGelato";

import { CallWithERC2771Struct } from "../../typechain/contracts/GelatoRelayERC2771";
import { CallWithConcurrentERC2771Struct } from "../../typechain/contracts/GelatoRelayConcurrentERC2771";

// EXTERNAL FUNCTIONS
// DIGESTS
export function generateDigest(
  _msg: MessageStruct,
  DOMAIN_SEPARATOR: string
): string {
  return _getDigest(_msg, DOMAIN_SEPARATOR);
}

export function generateDigestFeeCollector(
  _msg: MessageFeeCollectorStruct,
  DOMAIN_SEPARATOR: string
): string {
  return _getDigestFeeCollector(_msg, DOMAIN_SEPARATOR);
}

export function generateDigestRelayContext(
  _msg: MessageRelayContextStruct,
  DOMAIN_SEPARATOR: string
): string {
  return _getDigestRelayContext(_msg, DOMAIN_SEPARATOR);
}

export function generateDigestCallWithSyncFeeERC2771(
  _call: CallWithERC2771Struct,
  DOMAIN_SEPARATOR: string
): string {
  return _getDigestCallWithSyncFeeERC2771(_call, DOMAIN_SEPARATOR);
}

export function generateDigestCallWithSyncFeeConcurrentERC2771(
  _call: CallWithConcurrentERC2771Struct,
  DOMAIN_SEPARATOR: string
): string {
  return _getDigestCallWithSyncFeeConcurrentERC2771(_call, DOMAIN_SEPARATOR);
}

export function recoverAddress(digest: string, signature: string): string {
  return SigningKey.recoverPublicKey(digest, signature);
}

// INTERNAL FUNCTIONS
// DIGESTS
function _getDigest(_msg: MessageStruct, DOMAIN_SEPARATOR: string): string {
  // console.log("hashAbiEncode: ", keccak256(_abiEncodeExecWithSigs(_msg)));

  // console.log("abiEncoded: ", _abiEncodeExecWithSigs(_msg));
  return solidityPackedKeccak256(
    ["string", "bytes32", "bytes32"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      keccak256(_abiEncodeExecWithSigs(_msg)),
    ]
  );
}

function _getDigestFeeCollector(
  _msg: MessageFeeCollectorStruct,
  DOMAIN_SEPARATOR: string
): string {
  return solidityPackedKeccak256(
    ["string", "bytes", "bytes"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      keccak256(_abiEncodeExecWithSigsFeeCollector(_msg)),
    ]
  );
}

function _getDigestRelayContext(
  _msg: MessageRelayContextStruct,
  DOMAIN_SEPARATOR: string
): string {
  return solidityPackedKeccak256(
    ["string", "bytes", "bytes"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      keccak256(_abiEncodeExecWithSigsRelayContext(_msg)),
    ]
  );
}

function _getDigestCallWithSyncFeeERC2771(
  _call: CallWithERC2771Struct,
  DOMAIN_SEPARATOR: string
): string {
  return solidityPackedKeccak256(
    ["string", "bytes", "bytes"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      keccak256(_abiEncodeCallWithSyncFeeERC2771(_call)),
    ]
  );
}

function _getDigestCallWithSyncFeeConcurrentERC2771(
  _call: CallWithConcurrentERC2771Struct,
  DOMAIN_SEPARATOR: string
): string {
  return solidityPackedKeccak256(
    ["string", "bytes", "bytes"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      keccak256(_abiEncodeCallWithSyncFeeConcurrentERC2771(_call)),
    ]
  );
}

// ABI ENCODING STRUCTS
function _abiEncodeExecWithSigs(_msg: MessageStruct): string {
  const typeHash = _execWithSigsTypeHash();
  return new AbiCoder().encode(
    ["bytes32", "address", "bytes32", "uint256", "uint256"],
    [
      typeHash,
      _msg.service,
      keccak256(_msg.data as string),
      _msg.salt,
      _msg.deadline,
    ]
  );
}

function _abiEncodeExecWithSigsFeeCollector(
  _msg: MessageFeeCollectorStruct
): string {
  const typeHash = _execWithSigsFeeCollectorTypeHash();
  const abi = AbiCoder.defaultAbiCoder();
  const hashedPayload = keccak256(_msg.data as string);
  return abi.encode(
    ["bytes32", "address", "bytes32", "uint256", "uint256", "address"],
    [
      typeHash,
      _msg.service,
      hashedPayload,
      _msg.salt,
      _msg.deadline,
      _msg.feeToken,
    ]
  );
}

function _abiEncodeExecWithSigsRelayContext(
  _msg: MessageRelayContextStruct
): string {
  const typeHash = _execWithSigsRelayContextTypeHash();
  const abi = AbiCoder.defaultAbiCoder();
  const hashedPayload = keccak256(_msg.data as string);
  return abi.encode(
    [
      "bytes32",
      "address",
      "bytes32",
      "uint256",
      "uint256",
      "address",
      "uint256",
    ],
    [
      typeHash,
      _msg.service,
      hashedPayload,
      _msg.salt,
      _msg.deadline,
      _msg.feeToken,
      _msg.fee,
    ]
  );
}

function _abiEncodeCallWithSyncFeeERC2771(
  _call: CallWithERC2771Struct
): string {
  const typeHash = _callWithSyncFeeERC2771TypeHash();
  return new AbiCoder().encode(
    [
      "bytes32",
      "uint256",
      "address",
      "bytes32",
      "address",
      "uint256",
      "uint256",
    ],
    [
      typeHash,
      _call.chainId,
      _call.target,
      keccak256(_call.data as string),
      _call.user,
      _call.userNonce,
      _call.userDeadline,
    ]
  );
}

function _abiEncodeCallWithSyncFeeConcurrentERC2771(
  _call: CallWithConcurrentERC2771Struct
): string {
  const typeHash = _callWithSyncFeeConcurrentERC2771TypeHash();
  return new AbiCoder().encode(
    [
      "bytes32",
      "uint256",
      "address",
      "bytes32",
      "address",
      "bytes32",
      "uint256",
    ],
    [
      typeHash,
      _call.chainId,
      _call.target,
      keccak256(_call.data as string),
      _call.user,
      _call.userSalt,
      _call.userDeadline,
    ]
  );
}

// TYPE HASHES
function _execWithSigsTypeHash() {
  return keccak256(
    toUtf8Bytes(
      "Message(address service,bytes data,uint256 salt,uint256 deadline)"
    )
  );
}

function _execWithSigsFeeCollectorTypeHash() {
  return keccak256(
    toUtf8Bytes(
      "MessageFeeCollector(address service,bytes data,uint256 salt,uint256 deadline,address feeToken)"
    )
  );
}

function _execWithSigsRelayContextTypeHash() {
  return keccak256(
    toUtf8Bytes(
      "MessageRelayContext(address service,bytes data,uint256 salt,uint256 deadline,address feeToken,uint256 fee)"
    )
  );
}

function _callWithSyncFeeERC2771TypeHash() {
  return keccak256(
    toUtf8Bytes(
      "CallWithSyncFeeERC2771(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline)"
    )
  );
}

function _callWithSyncFeeConcurrentERC2771TypeHash() {
  return keccak256(
    toUtf8Bytes(
      "CallWithSyncFeeConcurrentERC2771(uint256 chainId,address target,bytes data,address user,bytes32 userSalt,uint256 userDeadline)"
    )
  );
}
