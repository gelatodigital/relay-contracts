// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Treasury is ITreasury {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable owner;
    address public immutable gelatoRelayer;

    mapping(address => mapping(address => uint256)) private _userTokenBalances;
    EnumerableSet.AddressSet private _paymentTokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }

    modifier onlyGelatoRelayer() {
        require(msg.sender == gelatoRelayer, "Only callable by Gelato Relayer");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only callable by EOA");
        _;
    }

    constructor(address _owner, address _gelatoRelayer) {
        owner = _owner;
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
        uint256 preBalance = paymentToken.balanceOf(address(this));
        SafeERC20.safeTransferFrom(
            paymentToken,
            msg.sender,
            address(this),
            _amount
        );
        uint256 postBalance = paymentToken.balanceOf(address(this));
        _incrementUserBalance(
            msg.sender,
            _paymentToken,
            postBalance - preBalance
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

    function incrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) external override onlyGelatoRelayer {
        _incrementUserBalance(_user, _token, _amount);
    }

    function decrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) external override onlyGelatoRelayer {
        _decrementUserBalance(_user, _token, _amount);
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

    function _decrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) private {
        uint256 userTokenBalance = userBalance(_user, _token);
        require(userTokenBalance >= _amount, "Insuficient user balance");
        _userTokenBalances[_user][_token] -= _amount;
    }

    function _incrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) private {
        _userTokenBalances[_user][_token] += _amount;
    }
}
