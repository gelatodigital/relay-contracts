// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {
    IGelatoRelay1BalanceERC2771Base
} from "../interfaces/IGelatoRelay1BalanceERC2771Base.sol";
import {GelatoString} from "../lib/GelatoString.sol";
import {CallWithERC2771} from "../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelay1BalanceERC2771Base is
    IGelatoRelay1BalanceERC2771Base
{
    using GelatoString for string;

    // solhint-disable-next-line named-parameters-mapping
    mapping(address => uint256) public userNonce;

    address public immutable gelato;

    bytes32 public constant SPONSORED_CALL_ERC2771_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsoredCallERC2771(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline)"
            )
        );

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    function _requireChainId(
        uint256 _chainId,
        string memory _errorTrace
    ) internal view {
        require(_chainId == block.chainid, _errorTrace.suffix("chainid"));
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

    function _requireSponsoredCallERC2771Signature(
        bytes32 _domainSeparator,
        CallWithERC2771 calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeSponsoredCallERC2771(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        // solhint-disable-next-line reason-string
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelay1BalanceERC2771Base._requireSponsoredCallERC2771Signature"
        );
    }

    function _abiEncodeSponsoredCallERC2771(
        CallWithERC2771 calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                SPONSORED_CALL_ERC2771_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.user,
                _call.userNonce,
                _call.userDeadline
            );
    }
}
