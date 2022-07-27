// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SponsorAuthCall} from "../types/CallTypes.sol";
import {UserSponsorAuthCall} from "../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelayBase {
    bytes32 public constant SPONSOR_AUTH_CALL_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsorAuthCall(uint256 chainId,address target,bytes data,address feeToken,uint256 paymentType,uint256 maxFee,address sponsor,uint256 sponsorChainId,uint256 nonce,bool enforceSponsorNonce,bool enforceSponsorNonceOrdering)"
            )
        );

    bytes32 public constant USER_SPONSOR_AUTH_CALL_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "UserSponsorAuthCall(uint256 chainId,address target,bytes data,address feeToken,uint256 paymentType,uint256 maxFee,address user,address sponsor,uint256 sponsorChainId,uint256 nonce,uint256 userDeadline)"
            )
        );

    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    address public immutable gelato;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _getDomainSeparator(block.chainid);
    }

    function _getDomainSeparator(uint256 _chainId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(bytes(EIP712_DOMAIN_TYPE)),
                    keccak256(bytes("GelatoRelay")),
                    keccak256(bytes("V1")),
                    bytes32(_chainId),
                    address(this)
                )
            );
    }

    function _verifySponsorAuthCallSignature(
        SponsorAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal view returns (bytes32) {
        bytes32 domainSeparator = _getDomainSeparator(_call.chainId);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(_abiEncodeSponsorAuthCall(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "Invalid signature"
        );

        return digest;
    }

    function _verifyUserSponsorAuthCallSignature(
        UserSponsorAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal view {
        bytes32 domainSeparator = _getDomainSeparator(_call.chainId);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(_abiEncodeUserSponsorAuthCall(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "Invalid signature"
        );
    }

    function _abiEncodeSponsorAuthCall(SponsorAuthCall calldata _call)
        internal
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            SPONSOR_AUTH_CALL_TYPEHASH,
            _call.chainId,
            _call.target,
            keccak256(_call.data),
            _call.feeToken,
            _call.paymentType,
            _call.maxFee,
            _call.sponsor,
            _call.sponsorChainId,
            _call.userNonce,
            _call.enforceSponsorNonce,
            _call.enforceSponsorNonceOrdering
        );
    }

    function _abiEncodeUserSponsorAuthCall(UserSponsorAuthCall calldata _call)
        internal
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            USER_SPONSOR_AUTH_CALL_TYPEHASH,
            _call.chainId,
            _call.target,
            keccak256(_call.data),
            _call.feeToken,
            _call.paymentType,
            _call.maxFee,
            _call.user,
            _call.sponsor,
            _call.sponsorChainId,
            _call.nonce,
            _call.userDeadline
        );
    }
}
