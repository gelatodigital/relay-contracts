// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GelatoCallUtils} from "./gelato/GelatoCallUtils.sol";
import {GelatoRelayBase} from "./base/GelatoRelayBase.sol";
import {GelatoTokenUtils} from "./gelato/GelatoTokenUtils.sol";
import {ForwardRequest} from "./structs/RequestTypes.sol";
import {IGelato} from "./interfaces/IGelato.sol";
import {MetaTxRequest} from "./structs/RequestTypes.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Gelato Meta Box contract
/// @notice This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here.
// solhint-disable-next-line max-states-count
contract GelatoRelay is Proxied, Initializable, GelatoRelayBase {
    // have to merge the base files as well
    address public immutable gelato;
    uint256 public immutable chainId;

    mapping(address => uint256) public nonce;
    mapping(bytes32 => bool) public messageDelivered;
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
    event LogMetaTxRequestAsyncGasTankFee(
        bytes32 indexed taskId,
        address indexed user
    );

    event LogMetaTxRequestSyncGasTankFee(
        bytes32 indexed taskId,
        address indexed user
    );

    event LogSetGasTank(address oldGasTank, address newGasTank);

    event LogSetGasTankAdmin(address oldGasTankAdmin, address newGasTankAdmin);

    event LogUseGelato1Balance(
        address indexed sponsor,
        address indexed service,
        address indexed feeToken,
        uint256 sponsorChainId,
        uint256 nativeToFeeTokenXRateNumerator,
        uint256 nativeToFeeTokenXRateDenominator
    );

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

    /// @notice Relay request + Sync Payment (target pays Gelato during call forward)
    /// @param _target Target smart contract
    /// @param _data Payload for call on _target
    /// @param _gas Gas limit
    /// @param _gelatoFee Fee to be charged, denominated in feeToken
    /// @param _taskId Unique task indentifier
    function forwardCallSyncFee(
        address _target,
        bytes calldata _data,
        address _feeToken,
        uint256 _gas,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        uint256 preBalance = GelatoTokenUtils.getBalance(
            _feeToken,
            address(this)
        );
        require(_target != gasTank, "target address cannot be gasTank");

        GelatoCallUtils.safeExternalCall(_target, _data, _gas);
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

    /// @notice Relay request + async Gas Tank payment deductions (off-chain accounting)
    /// @param _req Relay request data
    /// @param _sponsorSignature EIP-712 compliant signature from _req.sponsor
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    /// @notice Oracle value for exchange rate between native tokens and fee token
    /// @param  _nativeToFeeTokenXRateNumerator Exchange rate numerator
    /// @param  _nativeToFeeTokenXRateNumerator Exchange rate numerator
    /// @param _taskId Unique task indentifier
    // solhint-disable-next-line function-max-lines
    function forwardRequestGasTankFee(
        ForwardRequest calldata _req,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
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
        // We allow this option, BUT MAKE SURE _req.target IMPLEMENTS STRONG REPLAY PROTECTION!!
        if (_req.enforceSponsorNonce) {
            if (_req.enforceSponsorNonceOrdering) {
                // Enforce ordering on nonces,
                // If tx with nonce n reverts, so will txs with nonce n+1.
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

        require(_req.target != gasTank, "target address cannot be gasTank");

        GelatoCallUtils.safeExternalCall(_req.target, _req.data, _req.gas);

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

            emit LogUseGelato1Balance(
                _req.sponsor,
                address(this),
                _req.feeToken,
                chainId,
                _nativeToFeeTokenXRateNumerator,
                _nativeToFeeTokenXRateDenominator
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

    /// @notice Relay request + async Gas Tank payment deductions (off-chain accounting)
    /// @param _req Relay request data
    /// @param _userSignature EIP-712 compliant signature from _req.user
    /// @param _sponsorSignature EIP-712 compliant signature from _req.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    // solhint-disable-next-line function-max-lines
    function metaTxRequestGasTankFee(
        MetaTxRequest calldata _req,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        uint256 _nativeToFeeTokenXRateNumerator,
        uint256 _nativeToFeeTokenXRateDenominator,
        bytes32 _taskId
    ) external onlyGelato {
        require(
            // solhint-disable-next-line not-rely-on-time
            _req.deadline == 0 || _req.deadline >= block.timestamp,
            "Request expired"
        );

        require(_req.chainId == chainId, "Wrong chainId");

        require(
            _req.paymentType == 1 || _req.paymentType == 2,
            "paymentType must be 1 or 2"
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

        require(_req.target != gasTank, "target address cannot be gasTank");
        require(_isContract(_req.target), "Cannot call EOA");

        (bool success, ) = _req.target.call{gas: _req.gas}(
            abi.encodePacked(_req.data, _req.user)
        );

        require(success, "External call failed");

        if (_req.paymentType == 1) {
            emit LogMetaTxRequestAsyncGasTankFee(_taskId, _req.user);

            emit LogUseGelato1Balance(
                _req.sponsor,
                address(this),
                _req.feeToken,
                chainId,
                _nativeToFeeTokenXRateNumerator,
                _nativeToFeeTokenXRateDenominator
            );
        } else if (_req.paymentType == 2) {
            emit LogMetaTxRequestSyncGasTankFee(_taskId, _req.user);
        }
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _getDomainSeparator(chainId);
    }
}
