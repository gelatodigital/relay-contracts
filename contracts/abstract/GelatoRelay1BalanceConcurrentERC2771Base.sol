// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {
    IGelatoRelay1BalanceConcurrentERC2771Base
} from "../interfaces/IGelatoRelay1BalanceConcurrentERC2771Base.sol";
import {GelatoString} from "../lib/GelatoString.sol";
import {CallWithConcurrentERC2771} from "../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelay1BalanceConcurrentERC2771Base is
    IGelatoRelay1BalanceConcurrentERC2771Base
{
    using GelatoString for string;

    // solhint-disable-next-line named-parameters-mapping
    mapping(bytes32 => bool) public hashUsed;

    address public immutable gelato;

    bytes32 public constant SPONSORED_CALL_CONCURRENT_ERC2771_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsoredCallConcurrentERC2771(uint256 chainId,address target,bytes data,address user,bytes32 userSalt,uint256 userDeadline)"
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

    function _requireHash(
        bytes32 _callWithSyncFeeConcurrentHash,
        string memory _errorTrace
    ) internal view {
        require(
            !hashUsed[_callWithSyncFeeConcurrentHash],
            _errorTrace.suffix("replay")
        );
    }

    function _requireSponsoredCallConcurrentERC2771Signature(
        bytes32 _domainSeparator,
        bytes32 _sponsoredCallConcurrentHash,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                _sponsoredCallConcurrentHash
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        // solhint-disable-next-line reason-string
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            // solhint-disable-next-line max-line-length
            "GelatoRelay1BalanceConcurrentERC2771Base._requireSponsoredCallConcurrentERC2771Signature"
        );
    }

    function _hashSponsoredCallConcurrentERC2771(
        CallWithConcurrentERC2771 calldata _call
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SPONSORED_CALL_CONCURRENT_ERC2771_TYPEHASH,
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
