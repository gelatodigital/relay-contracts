// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITreasury {
    function addPaymentToken(address _paymentToken) external;

    function removePaymentToken(address _paymentToken) external;

    function depositEth() external payable;

    function withdrawEth(uint256 _amount) external;

    function depositBalance(address _paymentToken, uint256 _amount) external;

    function withdrawToken(address _paymentToken, uint256 _amount) external;

    function incrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) external;

    function decrementUserBalance(
        address _user,
        address _token,
        uint256 _amount
    ) external;

    function paymentTokens()
        external
        view
        returns (address[] memory paymentTokens_);

    function userBalance(address _user, address _token)
        external
        view
        returns (uint256 balance);
}
