// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {IGelatoRelayerTreasury} from "./interfaces/IGelatoRelayerTreasury.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GelatoRelayerTreasury is
    Proxied,
    OwnableUpgradeable,
    IGelatoRelayerTreasury
{
    using EnumerableSet for EnumerableSet.AddressSet;

    address public gelatoRelayer;
    mapping(address => mapping(address => uint256)) public userTokenBalances;
    EnumerableSet.AddressSet private _paymentTokens;

    modifier onlyGelatoRelayer() {
        require(msg.sender == gelatoRelayer, "Only callable by Gelato Relayer");
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function setGelatoRelayer(address _gelatoRelayer)
        external
        override
        onlyOwner
    {
        gelatoRelayer = _gelatoRelayer;
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

    function depositEth(address _receiver) external payable override {
        require(_receiver.code.length == 0, "Receiver must be EOA");

        require(msg.value > 0, "Invalid ETH deposit amount");

        require(_paymentTokens.contains(NATIVE_TOKEN), "ETH not whitelisted");

        _incrementUserBalance(_receiver, NATIVE_TOKEN, msg.value);
    }

    function withdrawEth(address _receiver, uint256 _amount) external override {
        require(_amount > 0, "Invalid ETH withdrawal amount");

        uint256 ethBalance = userTokenBalances[msg.sender][NATIVE_TOKEN];
        require(_amount <= ethBalance, "Insufficient balance");

        _decrementUserBalance(msg.sender, NATIVE_TOKEN, _amount);

        (bool success, ) = _receiver.call{value: _amount}("");
        require(success, "ETH withdrawal failed");
    }

    function depositToken(
        address _receiver,
        address _paymentToken,
        uint256 _amount
    ) external override {
        require(_receiver.code.length == 0, "Receiver must be EOA");

        require(_amount > 0, "Invalid deposit amount");

        require(
            _paymentTokens.contains(_paymentToken),
            "paymentToken not whitelisted"
        );
        require(_paymentToken != NATIVE_TOKEN, "paymentToken cannot be ETH");

        IERC20 paymentToken = IERC20(_paymentToken);

        uint256 preBalance = paymentToken.balanceOf(address(this));
        SafeERC20.safeTransferFrom(
            paymentToken,
            msg.sender,
            address(this),
            _amount
        );
        uint256 postBalance = paymentToken.balanceOf(address(this));

        _incrementUserBalance(
            _receiver,
            _paymentToken,
            postBalance - preBalance
        );
    }

    function withdrawToken(
        address _receiver,
        address _paymentToken,
        uint256 _amount
    ) external override {
        require(_amount > 0, "Invalid withdrawal amount");

        require(_paymentToken != NATIVE_TOKEN, "paymentToken cannot be ETH");

        uint256 balance = userTokenBalances[msg.sender][_paymentToken];
        require(_amount <= balance, "Insufficient balance");

        IERC20 paymentToken = IERC20(_paymentToken);
        _decrementUserBalance(msg.sender, _paymentToken, _amount);

        SafeERC20.safeTransfer(paymentToken, _receiver, _amount);
    }

    function chargeGelatoFee(
        address _user,
        address _token,
        uint256 _amount
    ) external override onlyGelatoRelayer {
        _decrementUserBalance(_user, _token, _amount);
        _incrementUserBalance(owner(), _token, _amount);
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

    function isPaymentToken(address _token)
        external
        view
        override
        returns (bool)
    {
        return _paymentTokens.contains(_token);
    }

    function _decrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) private {
        uint256 userTokenBalance = userTokenBalances[_user][_token];
        require(userTokenBalance >= _amount, "Insuficient user balance");

        userTokenBalances[_user][_token] -= _amount;
    }

    function _incrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) private {
        userTokenBalances[_user][_token] += _amount;
    }
}