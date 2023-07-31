// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {
    IGelatoRelayConcurrentERC2771Base
} from "../interfaces/IGelatoRelayConcurrentERC2771Base.sol";
import {GelatoString} from "../lib/GelatoString.sol";
import {CallWithConcurrentERC2771} from "../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelayConcurrentERC2771Base is
    IGelatoRelayConcurrentERC2771Base
{
    using GelatoString for string;

    // solhint-disable-next-line named-parameters-mapping
    mapping(bytes32 => bool) public hashUsed;

    address public immutable gelato;

    bytes32 public constant CALL_WITH_SYNC_FEE_CONCURRENT_ERC2771_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "CallWithSyncFeeConcurrentERC2771(uint256 chainId,address target,bytes data,address user,bytes32 userSalt,uint256 userDeadline)"
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

    function _requireUserDeadline(
        uint256 _userDeadline,
        string memory _errorTrace
    ) internal view {
        require(
            // solhint-disable-next-line not-rely-on-time
            _userDeadline == 0 || _userDeadline >= block.timestamp,
            _errorTrace.suffix("deadline")
        );
    }

    function _requireUnusedHash(
        bytes32 _callWithSyncFeeConcurrentHash,
        string memory _errorTrace
    ) internal view {
        require(
            !hashUsed[_callWithSyncFeeConcurrentHash],
            _errorTrace.suffix("replay")
        );
    }

    function _requireCallWithSyncFeeConcurrentERC2771Signature(
        bytes32 _domainSeparator,
        bytes32 _callWithSyncFeeConcurrentHash,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                _callWithSyncFeeConcurrentHash
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        // solhint-disable-next-line reason-string
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayConcurrentERC2771Base._requireCallWithSyncFeeConcurrentERC2771Signature"
        );
    }

    function _hashCallWithSyncFeeConcurrentERC2771(
        CallWithConcurrentERC2771 calldata _call
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CALL_WITH_SYNC_FEE_CONCURRENT_ERC2771_TYPEHASH,
                    _call.chainId,
                    _call.target,
                    keccak256(_call.data),
                    _call.user,
                    _call.userSalt,
                    _call.userDeadline
                )
            );
    }
}
