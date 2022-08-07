// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IGelatoRelayBase} from "./interfaces/IGelatoRelayBase.sol";
import {
    SponsorAuthCall,
    UserAuthCall,
    UserSponsorAuthCall
} from "./types/CallTypes.sol";
import {GelatoString} from "./lib/GelatoString.sol";
import {PaymentType} from "./types/PaymentTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelayBase is IGelatoRelayBase {
    using GelatoString for string;

    bytes32 public constant SPONSOR_AUTH_CALL_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsorAuthCall(uint256 chainId,address target,bytes data,address sponsor,uint256 sponsorSalt,uint8 paymentType,address feeToken,uint256 oneBalanceChainId,uint256 maxFee)"
            )
        );

    bytes32 public constant USER_AUTH_CALL_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "UserAuthCall(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline,uint8 paymentType,address feeToken,uint256 oneBalanceChainId,uint256 maxFee)"
            )
        );

    bytes32 public constant USER_SPONSOR_AUTH_CALL_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "UserSponsorAuthCall(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline,address sponsor,uint256 sponsorSalt,uint8 paymentType,address feeToken,uint256 oneBalanceChainId,uint256 maxFee)"
            )
        );

    address public immutable gelato;

    mapping(address => uint256) public userNonce;
    mapping(bytes32 => bool) public wasCallSponsoredAlready;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    function _requireBasics(
        uint256 _chainId,
        uint256 _gelatoFee,
        uint256 _maxFee,
        string memory _errorTrace
    ) internal view {
        require(_chainId == block.chainid, _errorTrace.suffix("chainid"));
        require(_gelatoFee <= _maxFee, _errorTrace.suffix("maxFee"));
    }

    function _requireUserBasics(
        uint256 _callUserNonce,
        uint256 _storedUserNonce,
        uint256 _userDeadline,
        string memory _errorTrace
    ) internal view {
        require(
            _callUserNonce == _storedUserNonce,
            _errorTrace.suffix("nonce")
        );
        require(
            // solhint-disable-next-line not-rely-on-time
            _userDeadline == 0 || _userDeadline >= block.timestamp,
            _errorTrace.suffix("deadline")
        );
    }

    function _verifySponsorAuthCallSignature(
        //solhint-disable-next-line
        bytes32 DOMAIN_SEPARATOR,
        SponsorAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(_abiEncodeSponsorAuthCall(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase._verifySponsorAuthCallSignature"
        );
    }

    function _verifyUserAuthCallSignature(
        //solhint-disable-next-line
        bytes32 DOMAIN_SEPARATOR,
        UserAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(_abiEncodeUserAuthCall(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase._verifyUserAuthCallSignature"
        );
    }

    function _verifyUserSponsorAuthCallSignature(
        //solhint-disable-next-line
        bytes32 DOMAIN_SEPARATOR,
        UserSponsorAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(_abiEncodeUserSponsorAuthCall(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase._verifyUserSponsorAuthCallSignature"
        );
    }

    function _abiEncodeSponsorAuthCall(SponsorAuthCall calldata _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                SPONSOR_AUTH_CALL_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.sponsor,
                _call.sponsorSalt,
                _call.paymentType,
                _call.feeToken,
                _call.oneBalanceChainId,
                _call.maxFee
            );
    }

    function _abiEncodeUserAuthCall(UserAuthCall calldata _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                USER_AUTH_CALL_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.user,
                _call.userNonce,
                _call.userDeadline,
                _call.paymentType,
                _call.feeToken,
                _call.oneBalanceChainId,
                _call.maxFee
            );
    }

    function _abiEncodeUserSponsorAuthCall(UserSponsorAuthCall calldata _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                USER_SPONSOR_AUTH_CALL_TYPEHASH,
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
                _call.oneBalanceChainId,
                _call.maxFee
            );
    }
}
