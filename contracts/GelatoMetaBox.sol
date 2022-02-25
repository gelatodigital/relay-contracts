// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Request} from "./structs/RequestTypes.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {IGelatoMetaBox} from "./interfaces/IGelatoMetaBox.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Gelato Meta Box contract
/// @notice This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here.
contract GelatoMetaBox is IGelatoMetaBox, Proxied {
    bytes32 public constant REQUEST_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Request(uint256 chainId,address target,bytes data,address feeToken,address user,address sponsor,uint256 nonce,uint256 deadline,bool isEIP2771)"
            )
        );
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    address public immutable gelato;
    uint256 public immutable chainId;
    bytes32 public immutable domainSeparator;

    mapping(address => uint256) public nonce;

    event ExecuteRequestSuccess(
        address indexed sponsor,
        address indexed user,
        address indexed target,
        address feeToken,
        uint256 fee
    );

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) {
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
                keccak256(bytes("GelatoMetaBox")),
                keccak256(bytes("V1")),
                bytes32(chainId),
                address(this)
            )
        );
    }

    /// @param _req Relay request data
    /// @param _userSignature EIP-712 compliant signature from _req.user
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    // solhint-disable-next-line function-max-lines
    function executeRequest(
        Request calldata _req,
        bytes calldata _userSignature,
        uint256 _gelatoFee
    ) external override onlyGelato {
        require(
            // solhint-disable-next-line not-rely-on-time
            _req.deadline == 0 || _req.deadline >= block.timestamp,
            "Request expired"
        );

        require(_req.chainId == chainId, "Wrong chainId");

        require(_req.nonce == nonce[_req.user], "Invalid nonce");

        _verifyUserSignature(_req, _userSignature, _req.user);

        nonce[_req.user]++;

        (bool success, ) = _req.target.call(
            _req.isEIP2771 ? abi.encodePacked(_req.data, _req.user) : _req.data
        );
        require(success, "Request call failed");

        emit ExecuteRequestSuccess(
            _req.sponsor,
            _req.user,
            _req.target,
            _req.feeToken,
            _gelatoFee
        );
    }

    function _verifyUserSignature(
        Request calldata _req,
        bytes calldata _userSignature,
        address _user
    ) private view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(_abiEncodeRequest(_req))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _userSignature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _user,
            "Invalid user signature"
        );
    }

    function _abiEncodeRequest(Request calldata _req)
        private
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            REQUEST_TYPEHASH,
            _req.chainId,
            _req.target,
            keccak256(_req.data),
            _req.feeToken,
            _req.user,
            _req.sponsor,
            _req.nonce,
            _req.deadline,
            _req.isEIP2771
        );
    }
}
