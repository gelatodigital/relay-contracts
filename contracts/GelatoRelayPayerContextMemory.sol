// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {
    IGelatoRelayPayerContextMemory
} from "./interfaces/IGelatoRelayPayerContextMemory.sol";
import {IGelato} from "./interfaces/IGelato.sol";
import {RelayContext} from "./types/CallTypes.sol";
import {GelatoCallUtils} from "./lib/GelatoCallUtils.sol";
import {GelatoTokenUtils} from "./lib/GelatoTokenUtils.sol";
import {
    _getFeeCollectorRelayContext,
    _getFeeTokenRelayContext,
    _getFeeRelayContext,
    _FEE_COLLECTOR_START
} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";

contract GelatoRelayPayerContextMemory is IGelatoRelayPayerContextMemory {
    using GelatoCallUtils for address;
    using GelatoTokenUtils for address;

    address public immutable gelato;

    mapping(address target => RelayContext relayContext)
        private _relayContextByTarget;

    IGelatoRelayPayerContextMemory
        private immutable _gelatoRelayPayerContextMemory;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    modifier onlyDelegatecall(string memory _info) {
        require(
            !_isCall(),
            string(abi.encodePacked(_info, ":onlyDelegatecall"))
        );
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
        _gelatoRelayPayerContextMemory = IGelatoRelayPayerContextMemory(
            address(this)
        );
    }

    function callWithSyncFeeStoreContext(
        address _target,
        bytes calldata _data,
        bytes32 _correlationId
    ) external onlyGelato {
        // We do not use relay context fee collector as reading from Gelato is safer
        address feeToken = _getFeeTokenRelayContext();
        uint256 fee = _getFeeRelayContext();

        _relayContextByTarget[_target] = RelayContext(feeToken, fee);

        _target.revertingContractCallNoCopy(
            _data,
            "GelatoRelayPayerContextMemory.callWithSyncFeeStoreContext:"
        );

        delete _relayContextByTarget[_target];

        emit LogCallWithSyncFeeStoreContext(_target, _correlationId);
    }

    function transferFeeDelegateCall(
        address _target
    )
        external
        onlyDelegatecall(
            "GelatoRelayPayerContextMemory.transferFeeDelegateCall"
        )
    {
        RelayContext memory relayContext = IGelatoRelayPayerContextMemory(
            _gelatoRelayPayerContextMemory
        ).getRelayContextByTarget(_target);

        address feeCollector = IGelato(gelato).feeCollector();
        require(feeCollector != address(0), "Invalid fee collector address");

        relayContext.feeToken.transfer(feeCollector, relayContext.fee);
    }

    function transferFeeCappedDelegateCall(
        address _target,
        uint256 _maxFee
    )
        external
        onlyDelegatecall(
            "GelatoRelayPayerContextMemory.transferFeeCappedDelegateCall"
        )
    {
        RelayContext memory relayContext = IGelatoRelayPayerContextMemory(
            _gelatoRelayPayerContextMemory
        ).getRelayContextByTarget(_target);

        // solhint-disable-next-line reason-string
        require(
            relayContext.fee <= _maxFee,
            "GelatoRelayPayerContextMemory.transferFeeCappedDelegateCall: maxFee"
        );

        address feeCollector = IGelato(gelato).feeCollector();
        require(feeCollector != address(0), "Invalid fee collector address");

        relayContext.feeToken.transfer(feeCollector, relayContext.fee);
    }

    function getRelayContextByTarget(
        address _target
    ) external view returns (RelayContext memory) {
        return _relayContextByTarget[_target];
    }

    function _isCall() internal view returns (bool) {
        return
            address(_gelatoRelayPayerContextMemory) == address(this)
                ? true
                : false;
    }
}
