// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Request} from "../structs/RequestTypes.sol";

interface IGelatoMetaBox {
    function executeRequest(
        Request calldata _req,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee
    ) external;
}
