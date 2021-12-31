// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {IGelatoRelayerRequestTypes} from "./IGelatoRelayerRequestTypes.sol";

interface IGelatoRelayer is IGelatoRelayerRequestTypes {
    function executeRequest(Request calldata _req, bytes calldata _signature)
        external;

    function setRelayerFeePct(uint256 _relayerFeePct) external;

    function addPaymentToken(address _paymentToken) external;

    function removePaymentToken(address _paymentToken) external;

    function depositEth() external payable;

    function withdrawEth(uint256 _amount) external;

    function depositBalance(address _paymentToken, uint256 _amount) external;

    function withdrawToken(address _paymentToken, uint256 _amount) external;

    function relayerNonce(address _from)
        external
        view
        returns (uint256 relayerNonce_);

    function paymentTokens()
        external
        view
        returns (address[] memory paymentTokens_);

    function userBalance(address _user, address _token)
        external
        view
        returns (uint256 balance);
}
