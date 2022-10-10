/* eslint-disable @typescript-eslint/naming-convention */
import { utils } from "ethers";
import {
  MessageStruct,
  MessageFeeCollectorStruct,
  MessageRelayContextStruct,
} from "../../typechain/contracts/interfaces/IGelato";

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

export function recoverAddress(digest: string, signature: string): string {
  const publicKey = utils.recoverPublicKey(digest, signature);
  return utils.computeAddress(publicKey);
}

// INTERNAL FUNCTIONS
// DIGESTS
function _getDigest(_msg: MessageStruct, DOMAIN_SEPARATOR: string): string {
  // console.log("hashAbiEncode: ", utils.keccak256(_abiEncodeExecWithSigs(_msg)));

  // console.log("abiEncoded: ", _abiEncodeExecWithSigs(_msg));
  return utils.solidityKeccak256(
    ["string", "bytes32", "bytes32"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      utils.keccak256(_abiEncodeExecWithSigs(_msg)),
    ]
  );
}

function _getDigestFeeCollector(
  _msg: MessageFeeCollectorStruct,
  DOMAIN_SEPARATOR: string
): string {
  return utils.solidityKeccak256(
    ["string", "bytes", "bytes"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      utils.keccak256(_abiEncodeExecWithSigsFeeCollector(_msg)),
    ]
  );
}

function _getDigestRelayContext(
  _msg: MessageRelayContextStruct,
  DOMAIN_SEPARATOR: string
): string {
  return utils.solidityKeccak256(
    ["string", "bytes", "bytes"],
    [
      "\x19\x01",
      DOMAIN_SEPARATOR,
      utils.keccak256(_abiEncodeExecWithSigsRelayContext(_msg)),
    ]
  );
}

// ABI ENCODING STRUCTS
function _abiEncodeExecWithSigs(_msg: MessageStruct): string {
  const typeHash = _execWithSigsTypeHash();
  return new utils.AbiCoder().encode(
    ["bytes32", "address", "bytes32", "uint256", "uint256"],
    [
      typeHash,
      _msg.service,
      utils.keccak256(_msg.data as string),
      _msg.salt,
      _msg.deadline,
    ]
  );
}

function _abiEncodeExecWithSigsFeeCollector(
  _msg: MessageFeeCollectorStruct
): string {
  const typeHash = _execWithSigsFeeCollectorTypeHash();
  const abi = utils.defaultAbiCoder;
  const hashedPayload = utils.keccak256(_msg.data as string);
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
  const abi = utils.defaultAbiCoder;
  const hashedPayload = utils.keccak256(_msg.data as string);
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

// TYPE HASHES
function _execWithSigsTypeHash() {
  return utils.keccak256(
    utils.toUtf8Bytes(
      "Message(address service,bytes data,uint256 salt,uint256 deadline)"
    )
  );
}

function _execWithSigsFeeCollectorTypeHash() {
  return utils.keccak256(
    utils.toUtf8Bytes(
      "MessageFeeCollector(address service,bytes data,uint256 salt,uint256 deadline,address feeToken)"
    )
  );
}

function _execWithSigsRelayContextTypeHash() {
  return utils.keccak256(
    utils.toUtf8Bytes(
      "MessageRelayContext(address service,bytes data,uint256 salt,uint256 deadline,address feeToken,uint256 fee)"
    )
  );
}
