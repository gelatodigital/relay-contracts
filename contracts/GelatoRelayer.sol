// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Request} from "./structs/RequestTypes.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {getBalance} from "./functions/TokenUtils.sol";
import {GelatoBytes} from "./libraries/GelatoBytes.sol";
import {GelatoString} from "./libraries/GelatoString.sol";
import {IGelatoRelayer} from "./interfaces/IGelatoRelayer.sol";
import {IGelatoRelayerTreasury} from "./interfaces/IGelatoRelayerTreasury.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice This contract must NEVER hold funds!
///         Malicious tx payloads could wipe out any funds left here.
contract GelatoRelayer is Proxied, OwnableUpgradeable, IGelatoRelayer {
    using GelatoBytes for bytes;
    using GelatoString for string;

    bytes32 public constant REQUEST_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Request(address from,address[] targets,bytes[] payloads,address feeToken,uint256 feeTokenPriceInNative,uint256 nonce,uint256 chainId,uint256 deadline,bool isSelfPayingTx,bool isFlashbotsTx,bool[] isTargetEIP2771Compliant)"
            )
        );
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    uint256 public constant DIAMOND_CALL_OVERHEAD = 33000;

    address public immutable gelato;
    uint256 public immutable chainId;
    bytes32 public immutable domainSeparator;
    IGelatoRelayerTreasury public immutable treasury;

    mapping(address => uint256) public nonces;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(
        address _gelato,
        address _treasury,
        string memory _version
    ) {
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
                keccak256(bytes("GelatoRelayer")),
                keccak256(bytes(_version)),
                bytes32(chainId),
                address(this)
            )
        );

        treasury = IGelatoRelayerTreasury(_treasury);
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function executeRequest(
        uint256 _gasCost,
        Request calldata _req,
        bytes calldata _signature
    ) external override onlyGelato returns (uint256 credit) {
        uint256 startGas = gasleft();

        _verifyDeadline(_req.deadline);

        _verifyChainId(_req.chainId);

        _verifyAndIncrementNonce(_req.nonce, _req.from);

        _verifySignature(_req, _signature);

        uint256 expectedCredit = _req.feeTokenPriceInNative * _gasCost;

        if (_req.isSelfPayingTx) {
            credit = _execSelfPayingTx(_req);
        } else {
            _execPrepaidTx(_req);

            credit = expectedCredit;

            if (credit > 0)
                treasury.chargeGelatoFee(_req.from, _req.feeToken, credit);
        }

        _verifyGasCost(_gasCost, startGas);
    }

    function withdrawTokens(
        address[] calldata _tokens,
        address[] calldata _receivers
    ) external override onlyOwner {
        require(_tokens.length == _receivers.length, "Array length mismatch");

        for (uint256 i; i < _tokens.length; i++) {
            _transferHandler(
                _tokens[i],
                _receivers[i],
                IERC20(_tokens[i]).balanceOf(address(this))
            );
        }
    }

    function _verifyAndIncrementNonce(uint256 _nonce, address _from) private {
        require(_nonce == nonces[_from], "Invalid nonce");

        nonces[_from] += 1;
    }

    function _transferHandler(
        address _paymentToken,
        address _receiver,
        uint256 _amount
    ) private {
        if (_paymentToken == NATIVE_TOKEN) {
            (bool success, ) = _receiver.call{value: _amount}("");
            require(success, "ETH payment failed");
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            SafeERC20.safeTransfer(paymentToken, _receiver, _amount);
        }
    }

    function _execSelfPayingTx(Request calldata _req)
        private
        returns (uint256 credit)
    {
        require(treasury.isPaymentToken(_req.feeToken), "Invalid feeToken");

        uint256 preBalance = getBalance(_req.feeToken, gelato);
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
        uint256 postBalance = getBalance(_req.feeToken, gelato);

        credit = postBalance - preBalance;
    }

    function _execPrepaidTx(Request calldata _req) private {
        _multiCall(
            _req.from,
            _req.targets,
            _req.isTargetEIP2771Compliant,
            _req.payloads
        );
    }

    function _multiCall(
        address _from,
        address[] calldata _targets,
        bool[] calldata _isTargetEIP2771Compliant,
        bytes[] calldata _payloads
    ) private {
        require(
            _targets.length == _payloads.length &&
                _targets.length == _isTargetEIP2771Compliant.length,
            "Array length mismatch"
        );

        for (uint256 i; i < _targets.length; i++) {
            require(
                _targets[i] != address(treasury),
                "Unsafe external call to Treasury"
            );

            (bool success, bytes memory returnData) = _targets[i].call(
                _isTargetEIP2771Compliant[i]
                    ? abi.encodePacked(_payloads[i], _from)
                    : _payloads[i]
            );

            if (!success)
                returnData.revertWithError("GelatoRelayerExecutor._multiCall:");
        }
    }

    function _verifyDeadline(uint256 _deadline) private view {
        require(
            // solhint-disable-next-line not-rely-on-time
            _deadline == 0 || block.timestamp <= _deadline,
            "Expired"
        );
    }

    function _verifyChainId(uint256 _chainId) private view {
        require(_chainId == chainId, "Invalid Chain Id");
    }

    function _verifySignature(Request calldata req, bytes calldata signature)
        private
        view
    {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(_abiEncodeRequest(req))
            )
        );

        address from = ECDSA.recover(message, signature);
        require(from == req.from, "Invalid signature");
    }

    function _verifyGasCost(uint256 _gasCost, uint256 _startGas) private view {
        uint256 gasCost = _startGas + DIAMOND_CALL_OVERHEAD - gasleft();
        require(_gasCost <= gasCost, "Executor overcharged in Gas Cost");
    }

    function _abiEncodeRequest(Request calldata _req)
        private
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            REQUEST_TYPEHASH,
            _req.from,
            keccak256(abi.encode(_req.targets)),
            keccak256(abi.encode(_req.payloads)),
            _req.feeToken,
            _req.feeTokenPriceInNative,
            _req.nonce,
            _req.chainId,
            _req.deadline,
            _req.isSelfPayingTx,
            _req.isFlashbotsTx,
            keccak256(abi.encode(_req.isTargetEIP2771Compliant))
        );
    }
}
