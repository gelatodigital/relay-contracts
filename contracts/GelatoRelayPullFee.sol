// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ForwardRequest} from "./structs/RequestTypes.sol";
import {MetaTxRequest} from "./structs/RequestTypes.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {GelatoRelayBase} from "./base/GelatoRelayBase.sol";
import {GelatoCallUtils} from "./gelato/GelatoCallUtils.sol";
import {IGelato} from "./interfaces/IGelato.sol";
import {IGelatoRelayAllowances} from "./interfaces/IGelatoRelayAllowances.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GelatoRelayPullFee is GelatoRelayBase, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable gelato;
    uint256 public immutable chainId;
    address public immutable gelatoRelayAllowances;

    mapping(address => uint256) public nonce;
    mapping(bytes32 => bool) public messageDelivered;
    EnumerableSet.AddressSet private _whitelistedDest;

    event LogForwardRequestPullFee(
        address indexed sponsor,
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogMetaTxRequestPullFee(
        address indexed sponsor,
        bytes32 indexed taskId,
        address indexed target,
        address feeToken,
        uint256 fee,
        address user
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
        gelatoRelayAllowances = address(0);
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

    /// @notice Relay forward request + pull fee from (transferFrom) _req.sponsor's address
    /// @dev    Assumes that _req.sponsor has approved this contract to spend _req.feeToken
    /// @param _req Relay request data
    /// @param _sponsorSignature EIP-712 compliant signature from _req.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function forwardRequestPullFee(
        ForwardRequest calldata _req,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
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
            if (_req.enforceSponsorNonceOrdering) {
                // Enforce ordering on nonces,
                // If tx with nonce n reverts, so will tx with nonce n+1.
                require(_req.nonce == nonce[_req.sponsor], "Invalid nonce");
                nonce[_req.sponsor] = _req.nonce + 1;

                _verifyForwardRequestSignature(
                    _req,
                    _sponsorSignature,
                    _req.sponsor
                );
            } else {
                // Do not enforce ordering on nonces,
                // but still enforce replay protection
                // via uniqueness of message
                bytes32 message = _verifyForwardRequestSignature(
                    _req,
                    _sponsorSignature,
                    _req.sponsor
                );
                require(!messageDelivered[message], "Task already executed");
                messageDelivered[message] = true;
            }
        } else {
            _verifyForwardRequestSignature(
                _req,
                _sponsorSignature,
                _req.sponsor
            );
        }

        _verifyForwardRequestSignature(_req, _sponsorSignature, _req.sponsor);
        // Gas optimization
        address pullFeeRegistryCopy = gelatoRelayAllowances;

        require(
            _req.target != pullFeeRegistryCopy,
            "Unsafe call to pullFeeRegistry"
        );
        GelatoCallUtils.safeExternalCall(_req.target, _req.data, _req.gas);

        IGelatoRelayAllowances(pullFeeRegistryCopy).pullFeeFrom(
            _req.feeToken,
            _req.sponsor,
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

    /// @notice Relay meta tx request + pull fee from (transferFrom) _req.sponsor's address
    /// @dev    Assumes that _req.sponsor has approved this contract to spend _req.feeToken
    /// @param _req Relay request data
    /// @param _userSignature EIP-712 compliant signature from _req.user
    /// @param _sponsorSignature EIP-712 compliant signature from _req.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    /// @notice Handles the case of tokens with fee on transfer
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function metaTxRequestPullFee(
        MetaTxRequest calldata _req,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato whenNotPaused {
        require(
            // solhint-disable-next-line not-rely-on-time
            _req.deadline == 0 || _req.deadline >= block.timestamp,
            "Request expired"
        );

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

        // Verify and increment user's nonce
        uint256 userNonce = nonce[_req.user];
        require(_req.nonce == userNonce, "Invalid nonce");
        nonce[_req.user] = userNonce + 1;

        _verifyMetaTxRequestSignature(_req, _userSignature, _req.user);
        // If is sponsored tx, we also verify sponsor's signature
        if (_req.user != _req.sponsor) {
            _verifyMetaTxRequestSignature(
                _req,
                _sponsorSignature,
                _req.sponsor
            );
        }
        // Gas optimization
        address pullFeeRegistryCopy = gelatoRelayAllowances;
        {
            require(
                _req.target != pullFeeRegistryCopy,
                "Unsafe call to pullFeeRegistry"
            );
            require(_isContract(_req.target), "Cannot call EOA");
            (bool success, ) = _req.target.call{gas: _req.gas}(
                abi.encodePacked(_req.data, _req.user)
            );
            require(success, "External call failed");
        }

        IGelatoRelayAllowances(pullFeeRegistryCopy).pullFeeFrom(
            _req.feeToken,
            _req.sponsor,
            _gelatoFee
        );

        emit LogMetaTxRequestPullFee(
            _req.sponsor,
            _taskId,
            _req.target,
            _req.feeToken,
            _gelatoFee,
            _req.user
        );
    }

    function getWhitelistedDest() external view returns (address[] memory) {
        return _whitelistedDest.values();
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _getDomainSeparator(chainId);
    }
}