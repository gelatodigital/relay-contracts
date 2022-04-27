// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ForwardedRequest} from "./structs/RequestTypes.sol";
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

/// @title Gelato Relay Forwarder Pull Fee contract
/// @notice Forward calls + fee payment with transferFrom sponsor's address to gelato
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here.
contract GelatoRelayForwarderPullFee is
    GelatoRelayForwarderBase,
    Ownable,
    Pausable
{
    address public immutable gelato;
    uint256 public immutable chainId;

    mapping(address => uint256) public nonce;
    mapping(address => bool) public whitelistedDest;

    event LogForwardedRequestPullFee(
        address indexed sponsor,
        address indexed target,
        bool indexed hasSponsorSignature,
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
            !whitelistedDest[_dest],
            "Destination address already whitelisted"
        );

        whitelistedDest[_dest] = true;
    }

    // solhint-disable-next-line function-max-lines
    function forwardedRequestPullFee(
        ForwardedRequest calldata _req,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        uint256 _minGelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        require(_req.chainId == chainId, "Wrong chainId");

        require(_req.paymentType == 3, "paymentType must be 3");

        require(whitelistedDest[_req.target], "target address not whitelisted");

        require(
            _req.feeToken != NATIVE_TOKEN,
            "Native token not supported for paymentType 3"
        );

        require(_gelatoFee <= _req.maxFee, "Executor over-charged");
        // When sponsor is also dApp user, it is detrimental UX to require two signatures
        // Hence we leave it as optional
        bool hasSponsorSignature = keccak256(_sponsorSignature) !=
            keccak256(new bytes(0));

        if (hasSponsorSignature) {
            // Verify and increment sponsor's nonce
            // We assume that all security is enforced on _req.target address,
            // hence we allow the sponsor to submit multiple transactions concurrently
            // In case one reverts, it won't stop the others from being executed
            uint256 sponsorNonce = nonce[_req.sponsor];
            require(_req.nonce >= sponsorNonce, "Task already executed");
            nonce[_req.sponsor] = sponsorNonce + 1;

            _verifyForwardedRequestSignature(
                _req,
                _sponsorSignature,
                _req.sponsor
            );
        }

        GelatoCallUtils.safeExternalCall(_req.target, _req.data);

        uint256 preBalance = GelatoTokenUtils.getBalance(_req.feeToken, gelato);
        SafeERC20.safeTransferFrom(
            IERC20(_req.feeToken),
            _req.sponsor,
            gelato,
            _gelatoFee
        );
        uint256 postBalance = GelatoTokenUtils.getBalance(
            _req.feeToken,
            gelato
        );

        uint256 fee = postBalance - preBalance;
        require(fee >= _minGelatoFee, "Insufficient fee");

        emit LogForwardedRequestPullFee(
            _req.sponsor,
            _req.target,
            hasSponsorSignature,
            _req.feeToken,
            fee,
            _taskId
        );
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _getDomainSeparator(chainId);
    }
}
