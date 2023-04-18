// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IEIP173Proxy {
    function transferOwnership(address newOwner) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable;

    function owner() external view returns (address);
}
