// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {IGelatoRelayer} from "./interfaces/IGelatoRelayer.sol";
import {IOracleAggregator} from "./interfaces/IOracleAggregator.sol";
import {IGelatoRelayerExecutor} from "./interfaces/IGelatoRelayerExecutor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// solhint-disable-next-line max-states-count
contract GelatoRelayer is IGelatoRelayer {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant REQUEST_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Request(address from,address[] targets,uint256 gasLimit,uint256 relayerNonce,uint256 chainId,uint256 deadline,uint256 paymentToken,bool[] isTargetEIP2771Compliant,bool isSelfPayingTx,bool isFlashbotsTx,bytes[] payloads)"
            )
        );
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)";
    uint256 public constant DIAMOND_CALL_OVERHEAD = 21000;

    address public immutable owner;
    address public immutable gelato;
    uint256 public immutable chainId;
    bytes32 public immutable domainSeparator;
    IOracleAggregator public immutable oracleAggregator;
    IGelatoRelayerExecutor public immutable gelatoRelayerExecutor;

    uint256 public relayerFeePct;
    mapping(address => uint256) private _relayerNonces;
    mapping(address => mapping(address => uint256)) private _userTokenBalances;
    EnumerableSet.AddressSet private _paymentTokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only callable by EOA");
        _;
    }

    constructor(
        address _owner,
        address _gelato,
        address _oracleAggregator,
        address _gelatoRelayerExecutor,
        uint256 _relayerFeePct,
        string memory _version
    ) {
        owner = _owner;
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
                address(this),
                bytes32(chainId)
            )
        );
        oracleAggregator = IOracleAggregator(_oracleAggregator);
        gelatoRelayerExecutor = IGelatoRelayerExecutor(_gelatoRelayerExecutor);
        relayerFeePct = _relayerFeePct;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function executeRequest(
        uint256 _gasCost,
        Request calldata _req,
        bytes calldata _signature
    ) external override onlyGelato {
        uint256 startGas = gasleft();
        _verifyDeadline(_req.deadline);
        _verifyGasLimit(_gasCost, _req.gasLimit);
        _verifyAndIncrementNonce(_req.relayerNonce, _req.from);
        _verifySignature(_req, _signature);
        _verifyChainId(_req.chainId);
        uint256 credit;
        if (_req.isSelfPayingTx) {
            uint256 excessCredit;
            (credit, excessCredit) = gelatoRelayerExecutor.execSelfPayingTx(
                _gasCost,
                relayerFeePct,
                _req
            );
            if (excessCredit > 0)
                _incrementUserBalance(
                    _req.from,
                    _req.paymentToken,
                    excessCredit
                );
        } else {
            credit = gelatoRelayerExecutor.execPrepaidTx(
                _gasCost,
                relayerFeePct,
                _req
            );
            _decrementUserBalance(_req.from, _req.paymentToken, credit);
        }
        _verifyGasCost(startGas, _gasCost);
    }

    function setRelayerFeePct(uint256 _relayerFeePct)
        external
        override
        onlyOwner
    {
        require(_relayerFeePct <= 100, "Invalid percentage");
        relayerFeePct = _relayerFeePct;
    }

    function addPaymentToken(address _paymentToken)
        external
        override
        onlyOwner
    {
        require(_paymentToken != address(0), "Invalid paymentToken address");
        require(
            !_paymentTokens.contains(_paymentToken),
            "paymentToken already whitelisted"
        );
        _paymentTokens.add(_paymentToken);
    }

    function removePaymentToken(address _paymentToken)
        external
        override
        onlyOwner
    {
        require(_paymentToken != address(0), "Invalid paymentToken address");
        require(
            _paymentTokens.contains(_paymentToken),
            "paymentToken not whitelisted"
        );
        _paymentTokens.remove(_paymentToken);
    }

    function depositEth() external payable override onlyEOA {
        require(msg.value > 0, "Invalid ETH deposit amount");
        require(_paymentTokens.contains(NATIVE_TOKEN), "ETH not whitelisted");
        _incrementUserBalance(msg.sender, NATIVE_TOKEN, msg.value);
    }

    function withdrawEth(uint256 _amount) external override onlyEOA {
        require(_amount > 0, "Invalid ETH withdrawal amount");
        uint256 ethBalance = userBalance(msg.sender, NATIVE_TOKEN);
        require(_amount <= ethBalance, "Insufficient balance");
        payable(msg.sender).transfer(_amount);
        _decrementUserBalance(msg.sender, NATIVE_TOKEN, _amount);
    }

    function depositBalance(address _paymentToken, uint256 _amount)
        external
        override
        onlyEOA
    {
        require(_amount > 0, "Invalid deposit amount");
        require(
            _paymentTokens.contains(_paymentToken),
            "paymentToken not whitelisted"
        );
        require(_paymentToken != NATIVE_TOKEN, "paymentToken cannot be ETH");
        IERC20 paymentToken = IERC20(_paymentToken);
        SafeERC20.safeTransferFrom(
            paymentToken,
            msg.sender,
            address(this),
            _amount
        );
        _incrementUserBalance(
            msg.sender,
            _paymentToken,
            paymentToken.balanceOf(address(this))
        );
    }

    function withdrawToken(address _paymentToken, uint256 _amount)
        external
        override
        onlyEOA
    {
        require(_amount > 0, "Invalid withdrawal amount");
        require(
            _paymentTokens.contains(_paymentToken),
            "paymentToken not whitelisted"
        );
        require(_paymentToken != NATIVE_TOKEN, "paymentToken cannot be ETH");
        uint256 balance = userBalance(msg.sender, _paymentToken);
        require(_amount <= balance, "Insufficient balance");
        IERC20 paymentToken = IERC20(_paymentToken);
        SafeERC20.safeTransfer(paymentToken, msg.sender, _amount);
        _decrementUserBalance(msg.sender, _paymentToken, _amount);
    }

    function relayerNonce(address _from)
        external
        view
        override
        returns (uint256 relayerNonce_)
    {
        relayerNonce_ = _relayerNonces[_from];
    }

    function paymentTokens()
        external
        view
        override
        returns (address[] memory paymentTokens_)
    {
        uint256 length = _paymentTokens.length();
        paymentTokens_ = new address[](length);
        for (uint256 i; i < length; i++) {
            paymentTokens_[i] = _paymentTokens.at(i);
        }
    }

    function userBalance(address _user, address _token)
        public
        view
        override
        returns (uint256 balance)
    {
        balance = _userTokenBalances[_user][_token];
    }

    function _verifyAndIncrementNonce(uint256 _relayerNonce, address _from)
        private
    {
        require(
            _relayerNonce == _relayerNonces[_from],
            "Invalid relayer nonce"
        );
        _relayerNonces[_from] += 1;
    }

    function _decrementUserBalance(
        address _user,
        address _token,
        uint256 _credit
    ) private {
        uint256 userTokenBalance = userBalance(_user, _token);
        require(userTokenBalance >= _credit, "Insuficient user balance");
        _userTokenBalances[_user][_token] -= _credit;
    }

    function _incrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) private {
        _userTokenBalances[_user][_token] += _amount;
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

    function _verifyGasCost(uint256 _startGas, uint256 _gasCost) private view {
        uint256 maxGasCost = DIAMOND_CALL_OVERHEAD + gasleft() - _startGas;
        require(_gasCost <= maxGasCost, "Executor overcharged in Gas Cost");
    }

    function _verifyGasLimit(uint256 _gasCost, uint256 _gasLimit) private pure {
        require(_gasCost <= _gasLimit, "Gas Cost > Gas Limit");
    }

    function _abiEncodeRequest(Request calldata req)
        private
        pure
        returns (bytes memory encodedReq)
    {
        encodedReq = abi.encode(
            REQUEST_TYPEHASH,
            req.from,
            req.targets,
            req.gasLimit,
            req.relayerNonce,
            req.chainId,
            req.deadline,
            req.isTargetEIP2771Compliant,
            req.isSelfPayingTx,
            req.isFlashbotsTx,
            keccak256(abi.encode(req.payloads))
        );
    }
}
