// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    IGelatoRelayBase1Balance
} from "../interfaces/IGelatoRelayBase1Balance.sol";
import {GelatoRelayBase} from "./GelatoRelayBase.sol";
import {
    SponsorAuthCallWith1Balance,
    UserAuthCallWith1Balance,
    UserSponsorAuthCallWith1Balance
} from "../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelayBase1Balance is
    IGelatoRelayBase1Balance,
    GelatoRelayBase
{
    bytes32 public constant SPONSOR_AUTH_CALL_1BALANCE_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsorAuthCallWith1Balance(uint256 chainId,address target,bytes data,address sponsor,uint256 sponsorSalt,uint8 paymentType,address feeToken,uint256 oneBalanceChainId)"
            )
        );

    bytes32 public constant USER_AUTH_CALL_1BALANCE_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "UserAuthCallWith1Balance(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline,uint8 paymentType,address feeToken,uint256 oneBalanceChainId)"
            )
        );

    bytes32 public constant USER_SPONSOR_AUTH_CALL_1BALANCE_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "UserSponsorAuthCallWith1Balance(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline,address sponsor,uint256 sponsorSalt,uint8 paymentType,address feeToken,uint256 oneBalanceChainId)"
            )
        );

    // solhint-disable-next-line no-empty-blocks
    constructor(address _gelato) GelatoRelayBase(_gelato) {}

    function _requireSponsorAuthCallSignature1Balance(
        bytes32 _domainSeparator,
        SponsorAuthCallWith1Balance calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeSponsorAuthCall1Balance(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase1Balance._requireSponsorAuthCallSignature1Balance"
        );
    }

    function _requireUserAuthCallSignature1Balance(
        bytes32 _domainSeparator,
        UserAuthCallWith1Balance calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeUserAuthCall1Balance(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase1Balance._requireUserAuthCallSignature1Balance"
        );
    }

    function _requireUserSponsorAuthCallSignature1Balance(
        bytes32 _domainSeparator,
        UserSponsorAuthCallWith1Balance calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeUserSponsorAuthCall1Balance(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase1Balance._requireUserSponsorAuthCallSignature1Balance"
        );
    }

    function _abiEncodeSponsorAuthCall1Balance(
        SponsorAuthCallWith1Balance calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                SPONSOR_AUTH_CALL_1BALANCE_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.sponsor,
                _call.sponsorSalt,
                _call.paymentType,
                _call.feeToken,
                _call.oneBalanceChainId
            );
    }

    function _abiEncodeUserAuthCall1Balance(
        UserAuthCallWith1Balance calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                USER_AUTH_CALL_1BALANCE_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.user,
                _call.userNonce,
                _call.userDeadline,
                _call.paymentType,
                _call.feeToken,
                _call.oneBalanceChainId
            );
    }

    function _abiEncodeUserSponsorAuthCall1Balance(
        UserSponsorAuthCallWith1Balance calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                USER_SPONSOR_AUTH_CALL_1BALANCE_TYPEHASH,
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
                _call.oneBalanceChainId
            );
    }
}
