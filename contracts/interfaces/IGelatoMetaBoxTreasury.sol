// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGelatoMetaBoxTreasury {
    function setGelatoPaymentManager(address _gelatoPaymentManager) external;

    function addPaymentToken(address _paymentToken) external;

    function removePaymentToken(address _paymentToken) external;

    function depositNative(address _sponsor) external payable;

    function depositToken(
        address _sponsor,
        address _paymentToken,
        uint256 _amount
    ) external;

    function debitSponsorBalance(
        address[] calldata _sponsors,
        address[][] calldata _feeTokens,
        uint256[][] calldata _fees
    ) external;

    function paymentTokens()
        external
        view
        returns (address[] memory paymentTokens_);

    function isPaymentToken(address _token) external view returns (bool);
}
