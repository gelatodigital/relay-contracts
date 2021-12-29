// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library GelatoString {
    function revertWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
    {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }
}
