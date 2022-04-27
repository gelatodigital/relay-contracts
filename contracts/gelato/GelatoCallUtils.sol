// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library GelatoCallUtils {
    /// @dev Safe generalized external call:
    ///      Ensures that _dest is not EOA + does not read call's return data
    function safeExternalCall(address _dest, bytes calldata _data) internal {
        require(
            _dest.code.length > 0,
            "GelatoCallUtils.safeExternalCall: _dest cannot be EOA"
        );

        (bool success, ) = _dest.call(_data);
        require(
            success,
            "GelatoCallUtils.safeExternalCall: External call failed"
        );
    }
}
