// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    GelatoRelayFeeCollector
} from "@gelatonetwork/relay-context/contracts/GelatoRelayFeeCollector.sol";

contract MockGelatoRelayFeeCollector is GelatoRelayFeeCollector {
    event LogFeeCollector(address feeCollector);

    function emitFeeCollector() external {
        // (bytes memory data, address feeCollector) = abi.decode(
        //     msg.data,
        //     (bytes, address)
        // )
        emit LogFeeCollector(address(0));
    }

    // solhint-disable-next-line no-empty-blocks
    function testOnlyGelatoRelay() external onlyGelatoRelay {}
}
