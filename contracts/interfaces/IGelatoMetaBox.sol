// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import {ForwardRequest, MetaTxRequest} from "../structs/RequestTypes.sol";

interface IGelatoMetaBox {
    function forwardedRequestGasTankFee(
        ForwardRequest calldata _req,
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
