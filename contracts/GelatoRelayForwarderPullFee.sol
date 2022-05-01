// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ForwardRequest} from "./structs/RequestTypes.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {GelatoRelayForwarderBase} from "./base/GelatoRelayForwarderBase.sol";
import {GelatoCallUtils} from "./gelato/GelatoCallUtils.sol";
import {GelatoTokenUtils} from "./gelato/GelatoTokenUtils.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Gelato Relay Forwarder Pull Fee contract
/// @notice Forward calls + fee payment with transferFrom sponsor's address to gelato
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here.
contract GelatoRelayForwarderPullFee is
    GelatoRelayForwarderBase,
    Ownable,
    Pausable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable gelato;
    uint256 public immutable chainId;

    mapping(address => uint256) public nonce;
    EnumerableSet.AddressSet private _whitelistedDest;

    event LogForwardRequestPullFee(
        address indexed sponsor,
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) Ownable() Pausable() {
        gelato = _gelato;

        uint256 _chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }

        chainId = _chainId;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function whitelistDest(address _dest) external onlyOwner {
        require(
            !_whitelistedDest.contains(_dest),
            "Destination address already whitelisted"
        );

        _whitelistedDest.add(_dest);
    }

    function delistDest(address _dest) external onlyOwner {
        require(
            _whitelistedDest.contains(_dest),
            "Destination address not whitelisted"
        );

        _whitelistedDest.remove(_dest);
    }

    // solhint-disable-next-line function-max-lines
    function forwardRequestPullFee(
        ForwardRequest calldata _req,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        require(_req.chainId == chainId, "Wrong chainId");

        require(_req.paymentType == 3, "paymentType must be 3");

        require(
            _whitelistedDest.contains(_req.target),
            "target address not whitelisted"
        );

        require(
            _req.feeToken != NATIVE_TOKEN,
            "Native token not supported for paymentType 3"
        );

        require(_gelatoFee <= _req.maxFee, "Executor over-charged");
        // Verify and increment sponsor's nonce
        // We assume that all security is enforced on _req.target address,
        // hence we allow the sponsor to submit multiple transactions concurrently
        // In case one reverts, it won't stop the others from being executed

        // Optionally, the dApp may not want to track smart contract nonces
        // We allow this option, BUT MAKE SURE _req.target implements strong replay protection!
        if (_req.enforceSponsorNonce) {
            uint256 sponsorNonce = nonce[_req.sponsor];
            require(_req.nonce >= sponsorNonce, "Task already executed");
            nonce[_req.sponsor] = sponsorNonce + 1;
        }

        _verifyForwardRequestSignature(_req, _sponsorSignature, _req.sponsor);

        GelatoCallUtils.safeExternalCall(_req.target, _req.data);

        SafeERC20.safeTransferFrom(
            IERC20(_req.feeToken),
            _req.sponsor,
            gelato,
            _gelatoFee
        );

        emit LogForwardRequestPullFee(
            _req.sponsor,
            _req.target,
            _req.feeToken,
            _gelatoFee,
            _taskId
        );
    }

    function getWhitelistedDest() external view returns (address[] memory) {
        uint256 length = _whitelistedDest.length();
        address[] memory addresses = new address[](length);

        for (uint256 i; i < length; i++) {
            addresses[i] = _whitelistedDest.at(i);
        }

        return addresses;
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _getDomainSeparator(chainId);
    }
}
