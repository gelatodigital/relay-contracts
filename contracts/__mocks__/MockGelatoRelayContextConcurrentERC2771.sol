// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {
    GelatoRelayContextERC2771
} from "@gelatonetwork/relay-context/contracts/GelatoRelayContextERC2771.sol";

contract MockGelatoRelayContextConcurrentERC2771 is GelatoRelayContextERC2771 {
    event LogMsgData(bytes data);
    event LogContext(
        address feeCollector,
        address feeToken,
        uint256 fee,
        address _msgSender
    );

    function emitContext() external {
        emit LogMsgData(_getMsgData());
        emit LogContext(
            _getFeeCollector(),
            _getFeeToken(),
            _getFee(),
            _getMsgSender()
        );
    }

    function testTransferRelayFee() external {
        _transferRelayFee();
    }

    function testTransferRelayFeeCapped(uint256 _maxFee) external {
        _transferRelayFeeCapped(_maxFee);
    }

    // solhint-disabl no-empty-blocks
    function testOnlyGelatoRelayConcurrentERC2771()
        external
        onlyGelatoRelayERC2771
    {}
}
