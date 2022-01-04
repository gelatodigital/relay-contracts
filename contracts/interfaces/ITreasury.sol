// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITreasury {
    function setGelatoRelayer(address _gelatoRelayer) external;

    function addPaymentToken(address _paymentToken) external;

    function removePaymentToken(address _paymentToken) external;

    function depositEth(address _receiver) external payable;

    function withdrawEth(address _receiver, uint256 _amount) external;

    function depositToken(
        address _receiver,
        address _paymentToken,
        uint256 _amount
    ) external;

    function withdrawToken(
        address _receiver,
        address _paymentToken,
        uint256 _amount
    ) external;

    function incrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) external;

    function creditUserPayment(
        address _user,
        address _token,
        uint256 _amount
    ) external;

    function paymentTokens()
        external
        view
        returns (address[] memory paymentTokens_);

    function isPaymentToken(address _token) external view returns (bool);
}
