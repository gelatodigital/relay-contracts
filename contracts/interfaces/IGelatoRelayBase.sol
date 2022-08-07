// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// solhint-disable func-name-mixedcase
interface IGelatoRelayBase {
    function userNonce(address _user) external view returns (uint256);

    function wasCallSponsoredAlready(bytes32 _digest)
        external
        view
        returns (bool);

    function SPONSOR_AUTH_CALL_TYPEHASH() external pure returns (bytes32);

    function USER_AUTH_CALL_TYPEHASH() external pure returns (bytes32);

    function USER_SPONSOR_AUTH_CALL_TYPEHASH() external pure returns (bytes32);
}
