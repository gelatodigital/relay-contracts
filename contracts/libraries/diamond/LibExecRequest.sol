// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library LibExecRequest {
    struct ExecRequestStorage {
        mapping(address => uint256) nonces;
    }

    bytes32 private constant _EXEC_REQUEST_STORAGE =
        keccak256("gelatorelayer.diamond.exec.request.storage");
}
