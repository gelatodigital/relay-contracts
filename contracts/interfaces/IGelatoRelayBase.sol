// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// solhint-disable func-name-mixedcase
interface IGelatoRelayBase {
    function userNonce(address _user) external view returns (uint256);

    function wasCallSponsoredAlready(bytes32 _digest)
        external
        view
        returns (bool);
}
