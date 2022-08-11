// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    IGelatoRelayBaseTransferFrom
} from "../interfaces/IGelatoRelayBaseTransferFrom.sol";
import {GelatoRelayBase} from "./GelatoRelayBase.sol";
import {GelatoString} from "../lib/GelatoString.sol";
import {
    SponsorAuthCallWithTransferFrom,
    UserAuthCallWithTransferFrom,
    UserSponsorAuthCallWithTransferFrom
} from "../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelayBaseTransferFrom is
    IGelatoRelayBaseTransferFrom,
    GelatoRelayBase
{
    using GelatoString for string;

    bytes32 public constant SPONSOR_AUTH_CALL_TRANSFER_FROM_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsorAuthCallWithTransferFrom(uint256 chainId,address target,bytes data,address sponsor,uint256 sponsorSalt,uint8 paymentType,address feeToken,uint256 maxFee)"
            )
        );

    bytes32 public constant USER_AUTH_CALL_TRANSFER_FROM_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "UserAuthCallWithTransferFrom(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline,uint8 paymentType,address feeToken,uint256 maxFee)"
            )
        );

    bytes32 public constant USER_SPONSOR_AUTH_CALL_TRANSFER_FROM_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "UserSponsorAuthCallWithTransferFrom(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline,address sponsor,uint256 sponsorSalt,uint8 paymentType,address feeToken,uint256 maxFee)"
            )
        );

    // solhint-disable-next-line no-empty-blocks
    constructor(address _gelato) GelatoRelayBase(_gelato) {}

    function _requireMaxFee(
        uint256 _gelatoFee,
        uint256 _maxFee,
        string memory _errorTrace
    ) internal pure {
        require(_gelatoFee <= _maxFee, _errorTrace.suffix("maxFee"));
    }

    function _requireSponsorAuthCallSignatureTransferFrom(
        bytes32 _domainSeparator,
        SponsorAuthCallWithTransferFrom calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeSponsorAuthCallTransferFrom(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBaseTransferFrom._requireSponsorAuthCallSignatureTransferFrom"
        );
    }

    function _requireUserAuthCallSignatureTransferFrom(
        bytes32 _domainSeparator,
        UserAuthCallWithTransferFrom calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeUserAuthCallTransferFrom(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBaseTransferFrom._requireUserAuthCallSignatureTransferFrom"
        );
    }

    function _requireUserSponsorAuthCallSignatureTransferFrom(
        bytes32 _domainSeparator,
        UserSponsorAuthCallWithTransferFrom calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeUserSponsorAuthCallTransferFrom(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBaseTransferFrom._requireUserSponsorAuthCallSignatureTransferFrom"
        );
    }

    function _abiEncodeSponsorAuthCallTransferFrom(
        SponsorAuthCallWithTransferFrom calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                SPONSOR_AUTH_CALL_TRANSFER_FROM_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.sponsor,
                _call.sponsorSalt,
                _call.paymentType,
                _call.feeToken,
                _call.maxFee
            );
    }

    function _abiEncodeUserAuthCallTransferFrom(
        UserAuthCallWithTransferFrom calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                USER_AUTH_CALL_TRANSFER_FROM_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.user,
                _call.userNonce,
                _call.userDeadline,
                _call.paymentType,
                _call.feeToken,
                _call.maxFee
            );
    }

    function _abiEncodeUserSponsorAuthCallTransferFrom(
        UserSponsorAuthCallWithTransferFrom calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                USER_SPONSOR_AUTH_CALL_TRANSFER_FROM_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.user,
                _call.userNonce,
                _call.userDeadline,
                _call.sponsor,
                _call.sponsorSalt,
                _call.paymentType,
                _call.feeToken,
                _call.maxFee
            );
    }
}
