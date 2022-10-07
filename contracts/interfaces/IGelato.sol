// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ExecWithSigs,
    ExecWithSigsFeeCollector,
    ExecWithSigsRelayContext,
    Message,
    MessageFeeCollector,
    MessageRelayContext
} from "../types/DiamondCallTypes.sol";

// solhint-disable ordering

/// @dev includes the interfaces of all facets
interface IGelato {
    // ########## Ownership Facet #########
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);

    // ########## ExecAccessFacet #########

    function addExecutors(address[] calldata _executors) external;

    function removeExecutors(address[] calldata _executors) external;

    function canExec(address _executor) external view returns (bool);

    function isExecutor(address _executor) external view returns (bool);

    function executors() external view returns (address[] memory);

    function numberOfExecutors() external view returns (uint256);

    // ########## ExecFacet #########

    event LogExecSuccess(
        address indexed executor,
        address indexed service,
        address creditToken,
        uint256 credit,
        uint256 gasDebitInCreditToken,
        uint256 gasDebitInNativeToken
    );

    function exec(
        address _service,
        bytes calldata _data,
        address _creditToken
    )
        external
        returns (
            uint256 credit,
            uint256 creditInNativeToken,
            uint256 gasDebitInNativeToken,
            uint256 estimatedGasUsed
        );

    // ########## ExecWithSigsFacet #########

    event LogExecWithSigs(
        bytes32 correlationId,
        Message msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsFeeCollector(
        bytes32 correlationId,
        MessageFeeCollector msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 fee,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsRelayContext(
        bytes32 correlationId,
        MessageRelayContext msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 actualFee,
        uint256 estimatedGasUsed,
        address sender
    );

    function execWithSigs(ExecWithSigs calldata _data)
        external
        returns (uint256 estimatedGasUsed);

    function execWithSigsFeeCollector(ExecWithSigsFeeCollector calldata _call)
        external
        returns (uint256 estimatedGasUsed, uint256 fee);

    function execWithSigsRelayContext(ExecWithSigsRelayContext calldata _call)
        external
        returns (uint256 estimatedGasUsed, uint256 fee);

    function simulateBatchExecWithSigs(ExecWithSigs[] calldata _calls)
        external
        returns (bool[] memory callStatus, uint256[] memory gasUsed);

    function simulateBatchExecWithSigsFeeCollector(
        ExecWithSigsFeeCollector[] calldata _calls
    ) external returns (bool[] memory callStatus, uint256[] memory gasUsed);

    function simulateBatchExecWithSigsRelayContext(
        ExecWithSigsRelayContext[] calldata _calls
    ) external returns (bool[] memory callStatus, uint256[] memory gasUsed);

    function feeCollector() external view returns (address);

    //solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function MESSAGE_TYPEHASH() external pure returns (bytes32);

    function MESSAGE_FEE_COLLECTOR_TYPEHASH() external pure returns (bytes32);

    function MESSAGE_RELAY_CONTEXT_TYPEHASH() external pure returns (bytes32);

    function name() external pure returns (string memory);

    function version() external pure returns (string memory);

    // ########## SignerFacet #########

    function addExecutorSigners(address[] calldata _executorSigners) external;

    function removeExecutorSigners(address[] calldata _executorSigners)
        external;

    function isExecutorSigner(address _executorSigner)
        external
        view
        returns (bool);

    function numberOfExecutorSigners() external view returns (uint256);

    function executorSigners() external view returns (address[] memory);

    function addCheckerSigners(address[] calldata _checkerSigners) external;

    function removeCheckerSigners(address[] calldata _checkerSigners) external;

    function isCheckerSigner(address _checkerSigner)
        external
        view
        returns (bool);

    function numberOfCheckerSigners() external view returns (uint256);

    function checkerSigners() external view returns (address[] memory);

    // ########## TransferFacet #########

    function transfer(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external;
}
