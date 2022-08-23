// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IGelatoRelayBase} from "./IGelatoRelayBase.sol";

// solhint-disable func-name-mixedcase
interface IGelatoRelayBase1Balance is IGelatoRelayBase {
    function SPONSOR_AUTH_CALL_1BALANCE_TYPEHASH()
        external
        pure
        returns (bytes32);

    function USER_AUTH_CALL_1BALANCE_TYPEHASH() external pure returns (bytes32);

    function USER_SPONSOR_AUTH_CALL_1BALANCE_TYPEHASH()
        external
        pure
        returns (bytes32);
}
