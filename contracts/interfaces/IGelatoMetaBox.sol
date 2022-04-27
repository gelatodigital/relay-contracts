// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {ForwardedRequest, MetaTxRequest} from "../structs/RequestTypes.sol";

interface IGelatoMetaBox {
    function forwardedRequestGasTankFee(
        ForwardedRequest calldata _req,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;

    function metaTxRequestGasTankFee(
        MetaTxRequest calldata _req,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external;
}
