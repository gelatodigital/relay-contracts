// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    GelatoRelayFeeCollector
} from "@gelatonetwork/relay-context/contracts/GelatoRelayFeeCollector.sol";

contract MockGelatoRelayFeeCollector is GelatoRelayFeeCollector {
    event LogMsgData(bytes data);
    event LogFeeCollector(address feeCollector);

    function emitFeeCollector() external {
        emit LogMsgData(_getMsgData());
        emit LogFeeCollector(_getFeeCollector());
    }

    // solhint-disable-next-line no-empty-blocks
    function testOnlyGelatoRelay() external onlyGelatoRelay {}
}
