// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Request} from "../structs/RequestTypes.sol";
import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {LibExecRequest} from "../libraries/diamond/LibExecRequest.sol";
import {LibTransfer} from "../libraries/diamond/LibTransfer.sol";

/// @title Gelato Multichain Relay Facet
/// @notice This contract must NEVER hold funds!
///         Malicious tx payloads could wipe out any funds left here.
contract ExecRequestFacet {
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    uint256 public constant DIAMOND_CALL_OVERHEAD = 33000;

    address public immutable gelato;
    address public immutable treasury;
    bytes32 public immutable domainSeparator;

    event ExecuteRequestSuccess(
        address indexed relayerAddress,
        address indexed user,
        bool indexed isSelfPayingTx,
        address[] targets,
        uint256 credit,
        uint256 maxFee
    );

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(
        address _gelato,
        address _treasury,
        string memory _version
    ) {
        gelato = _gelato;

        uint256 _chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }

        treasury = _treasury;

        domainSeparator = keccak256(
            abi.encode(
                keccak256(bytes(EIP712_DOMAIN_TYPE)),
                keccak256(bytes("GelatoRelayer")),
                keccak256(bytes(_version)),
                bytes32(_chainId),
                address(this)
            )
        );
    }

    /// @param _req Relay request data
    /// @param _signature EIP-712 compliant signature
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    /// @return credit Amount paid by user (_req.from) denominated in Native token
    // solhint-disable-next-line function-max-lines
    function executeRequest(
        Request calldata _req,
        bytes calldata _signature,
        uint256 _gelatoFee
    ) external onlyGelato returns (uint256 credit) {
        LibExecRequest.verifyDeadline(_req.deadline);

        LibExecRequest.verifyChainId(_req.chainId);

        LibExecRequest.verifyAndIncrementNonce(_req.nonce, _req.from);

        LibExecRequest.verifySignature(domainSeparator, _req, _signature);

        LibExecRequest.verifyGelatoFee(_req.maxFee, _gelatoFee);

        if (_req.isSelfPayingTx) {
            credit = LibExecRequest.execSelfPayingTx(
                gelato,
                treasury,
                _req,
                _gelatoFee
            );

            LibTransfer.handleTransfer(_req.feeToken, gelato, credit);
        } else {
            LibExecRequest.execPrepaidTx(treasury, _req);
            // Credit to be accounted off-chain
            credit = _gelatoFee;
        }

        emit ExecuteRequestSuccess(
            tx.origin,
            _req.from,
            _req.isSelfPayingTx,
            _req.targets,
            credit,
            _req.maxFee
        );
    }

    function getNonce(address _from) external view returns (uint256) {
        return LibExecRequest.getNonce(_from);
    }
}
