// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISafeProxyFactory {
    event ProxyCreation(address proxy, address singleton);

    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address proxy);
}
