// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Request} from "../structs/RequestTypes.sol";

interface IGelatoMultichainRelayDiamond {
    /// ExecRequestFacet
    function executeRequest(
        Request calldata _req,
        bytes calldata _signature,
        uint256 _gelatoFee
    ) external returns (uint256 credit);

    function getNonce(address _from) external view returns (uint256);

    function gelato() external view returns (address);

    function gelatoRelayerTreasury() external view returns (address);

    function domainSeparator() external view returns (bytes32);

    // TransferFacet
    // solhint-disable-next-line ordering
    function withdrawTokens(
        address[] calldata _tokens,
        address[] calldata _receivers
    ) external;
}
