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
                "SponsorAuthCall(uint256 chainId,address target,bytes data,address sponsor,uint256 sponsorNonce,uint8 paymentType,address feeToken,uint256 oneBalanceChainId,uint256 maxFee)"
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
                "UserSponsorAuthCall(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline,address sponsor,uint256 sponsorNonce,uint8 paymentType,address feeToken,uint256 oneBalanceChainId,uint256 maxFee)"
            )
        );

    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    address public immutable gelato;
    bytes32 public immutable domainSeparator;

    mapping(address => uint256) public userNonce;
    mapping(bytes32 => bool) public wasCallSponsoredAlready;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
        domainSeparator = keccak256(
            abi.encode(
                keccak256(bytes(EIP712_DOMAIN_TYPE)),
                keccak256(bytes("GelatoRelay")),
                keccak256(bytes("V1")),
                bytes32(block.chainid),
                address(this)
            )
        );
    }

    function _requireBasics(
        uint256 _chainId,
        PaymentType _paymentType,
        uint256 _gelatoFee,
        uint256 _maxFee,
        string memory _errorTrace
    ) internal view {
        require(_chainId == block.chainid, _errorTrace.suffix("chainid"));
        require(
            _paymentType == PaymentType.OneBalance,
            _errorTrace.suffix("paymentType")
        );
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
        SponsorAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal view returns (bytes32 digest) {
        digest = keccak256(
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
            "GelatoRelayBase._verifySponsorAuthCallSignature"
        );
    }

    function _verifyUserAuthCallSignature(
        UserAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
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
        UserSponsorAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal view returns (bytes32 digest) {
        digest = keccak256(
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
                _call.sponsorNonce,
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
                _call.sponsorNonce,
                _call.paymentType,
                _call.feeToken,
                _call.oneBalanceChainId,
                _call.maxFee
            );
    }
}
