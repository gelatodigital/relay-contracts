// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGelatoMultichainRelayTreasury {
    function setGelatoRelayer(address _gelatoRelayer) external;

    function addPaymentToken(address _paymentToken) external;

    function removePaymentToken(address _paymentToken) external;

    function depositEth(address _receiver) external payable;

    function depositToken(
        address _receiver,
        address _paymentToken,
        uint256 _amount
    ) external;

    function collectFees(
        address[] calldata _tokens,
        address[] calldata _receivers,
        uint256[] calldata _amounts
    ) external;

    function paymentTokens()
        external
        view
        returns (address[] memory paymentTokens_);

    function isPaymentToken(address _token) external view returns (bool);
}
