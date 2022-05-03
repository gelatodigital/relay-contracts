// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ForwardRequest} from "./structs/RequestTypes.sol";
import {GelatoRelayForwarderBase} from "./base/GelatoRelayForwarderBase.sol";
import {GelatoCallUtils} from "./gelato/GelatoCallUtils.sol";
import {GelatoTokenUtils} from "./gelato/GelatoTokenUtils.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Gelato Relay Forwarder contract
/// @notice This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here.
contract GelatoRelayForwarder is
    Proxied,
    Initializable,
    GelatoRelayForwarderBase
{
    address public immutable gelato;
    uint256 public immutable chainId;

    mapping(address => uint256) public nonce;
    address public gasTank;
    address public gasTankAdmin;

    event LogForwardCallSyncFee(
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogForwardRequestAsyncGasTankFee(
        address indexed sponsor,
        address indexed target,
        uint256 sponsorChainId,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogForwardRequestSyncGasTankFee(
        address indexed sponsor,
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogSetGasTank(address oldGasTank, address newGasTank);

    event LogSetGasTankAdmin(address oldGasTankAdmin, address newGasTankAdmin);

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    modifier onlyGasTankAdmin() {
        require(msg.sender == gasTankAdmin, "Only callable by gasTankAdmin");
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
    }

    function init(address _gasTankAdmin) external initializer {
        gasTankAdmin = _gasTankAdmin;

        emit LogSetGasTankAdmin(address(0), _gasTankAdmin);
    }

    function setGasTank(address _gasTank) external onlyGasTankAdmin {
        require(_gasTank != address(0), "Invalid gasTank address");

        emit LogSetGasTank(gasTank, _gasTank);

        gasTank = _gasTank;
    }

    function setGasTankAdmin(address _gasTankAdmin) external onlyGasTankAdmin {
        require(_gasTankAdmin != address(0), "Invalid gasTankAdmin address");

        emit LogSetGasTankAdmin(gasTankAdmin, _gasTankAdmin);

        gasTankAdmin = _gasTankAdmin;
    }

    function forwardCallSyncFee(
        address _target,
        bytes calldata _data,
        address _feeToken,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        uint256 preBalance = GelatoTokenUtils.getBalance(
            _feeToken,
            address(this)
        );
        require(_target != gasTank, "target address cannot be gasTank");
        GelatoCallUtils.safeExternalCall(_target, _data);
        uint256 postBalance = GelatoTokenUtils.getBalance(
            _feeToken,
            address(this)
        );

        uint256 amount = postBalance - preBalance;
        require(amount >= _gelatoFee, "Insufficient fee");
        // TODO: change fee collector
        GelatoTokenUtils.transferToGelato(gelato, _feeToken, amount);

        emit LogForwardCallSyncFee(_target, _feeToken, amount, _taskId);
    }

    // solhint-disable-next-line function-max-lines
    function forwardRequestGasTankFee(
        ForwardRequest calldata _req,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        require(_req.chainId == chainId, "Wrong chainId");

        require(
            _req.paymentType == 1 || _req.paymentType == 2,
            "paymentType must be 1 or 2"
        );

        require(_gelatoFee <= _req.maxFee, "Gelato executor over-charged");

        // Verify and increment sponsor's nonce
        // We assume that all security is enforced on _req.target address,
        // hence we allow the sponsor to submit multiple transactions concurrently
        // In case one reverts, it won't stop the following ones from being executed

        // Optionally, the dApp may not want to track smart contract nonces
        // We allow this option, BUT MAKE SURE _req.target implements strong replay protection!
        if (_req.enforceSponsorNonce) {
            uint256 sponsorNonce = nonce[_req.sponsor];
            require(_req.nonce >= sponsorNonce, "Task already executed");
            nonce[_req.sponsor] = sponsorNonce + 1;
        }

        _verifyForwardRequestSignature(_req, _sponsorSignature, _req.sponsor);

        require(_req.target != gasTank, "target address cannot be gasTank");
        GelatoCallUtils.safeExternalCall(_req.target, _req.data);

        if (_req.paymentType == 1) {
            // GasTank payment with asynchronous fee crediting
            emit LogForwardRequestAsyncGasTankFee(
                _req.sponsor,
                _req.target,
                _req.sponsorChainId == 0 ? chainId : _req.sponsorChainId,
                _req.feeToken,
                _gelatoFee,
                _taskId
            );
        } else {
            // TODO: deduct balance from GasTank
            // Credit GasTank fee
            emit LogForwardRequestSyncGasTankFee(
                _req.sponsor,
                _req.target,
                _req.feeToken,
                _gelatoFee,
                _taskId
            );
        }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _getDomainSeparator(chainId);
    }
}
