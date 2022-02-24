// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {IGelatoMetaBoxTreasury} from "./interfaces/IGelatoMetaBoxTreasury.sol";
import {Transfer} from "./libraries/Transfer.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// solhint-disable-next-line max-states-count
contract GelatoMetaBoxTreasury is Proxied, IGelatoMetaBoxTreasury {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable gelato;

    address public gelatoPaymentManager;
    mapping(address => uint256) public sponsorNativeBalance;
    mapping(address => mapping(address => uint256)) public sponsorTokenBalance;

    EnumerableSet.AddressSet private _paymentTokens;

    modifier onlyGelatoPaymentManager() {
        require(
            msg.sender == gelatoPaymentManager,
            "Only gelato payment manager"
        );
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    function setGelatoPaymentManager(address _gelatoPaymentManager)
        external
        override
        onlyProxyAdmin
    {
        gelatoPaymentManager = _gelatoPaymentManager;
    }

    function addPaymentToken(address _paymentToken)
        external
        override
        onlyGelatoPaymentManager
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
        onlyGelatoPaymentManager
    {
        require(_paymentToken != address(0), "Invalid paymentToken address");

        require(
            _paymentTokens.contains(_paymentToken),
            "paymentToken not whitelisted"
        );

        _paymentTokens.remove(_paymentToken);
    }

    function depositNative(address _sponsor) external payable override {
        require(_sponsor.code.length == 0, "Sponsor must be EOA");
        require(msg.value > 0, "Invalid Native token deposit amount");

        sponsorNativeBalance[_sponsor] += msg.value;
        Transfer.transfer(NATIVE_TOKEN, gelato, msg.value);
    }

    function depositToken(
        address _sponsor,
        address _paymentToken,
        uint256 _amount
    ) external override {
        require(_sponsor.code.length == 0, "Sponsor must be EOA");

        require(_amount > 0, "Invalid deposit amount");

        require(
            _paymentTokens.contains(_paymentToken),
            "paymentToken not whitelisted"
        );

        IERC20 paymentToken = IERC20(_paymentToken);

        uint256 preBalance = paymentToken.balanceOf(gelato);
        SafeERC20.safeTransferFrom(paymentToken, msg.sender, gelato, _amount);
        uint256 postBalance = paymentToken.balanceOf(gelato);

        uint256 amount = postBalance - preBalance;
        sponsorTokenBalance[_sponsor][_paymentToken] += amount;
    }

    function creditOutstandingFees(
        address[] calldata _sponsors,
        address[][] calldata _feeTokens,
        uint256[][] calldata _fees
    ) external override onlyGelatoPaymentManager {
        require(
            _sponsors.length == _feeTokens.length &&
                _feeTokens.length == _fees.length,
            "Array length mismatch"
        );

        for (uint256 i; i < _sponsors.length; i++) {
            address sponsor = _sponsors[i];
            address[] memory tokens = _feeTokens[i];

            for (uint256 j; j < tokens.length; j++) {
                address token = tokens[j];

                if (token == NATIVE_TOKEN) {
                    sponsorNativeBalance[sponsor] -= _fees[i][j];
                } else {
                    sponsorTokenBalance[sponsor][token] -= _fees[i][j];
                }
            }
        }
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
}
