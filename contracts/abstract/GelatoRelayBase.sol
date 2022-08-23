// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IGelatoRelayBase} from "../interfaces/IGelatoRelayBase.sol";
import {GelatoString} from "../lib/GelatoString.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelayBase is IGelatoRelayBase {
    using GelatoString for string;

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

    function _requireChainId(uint256 _chainId, string memory _errorTrace)
        internal
        view
    {
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
}
