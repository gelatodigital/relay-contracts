// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Request} from "../structs/RequestTypes.sol";
import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {LibExecRequest} from "../libraries/diamond/LibExecRequest.sol";
import {IGelatoRelayerTreasury} from "../interfaces/IGelatoRelayerTreasury.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice This contract must NEVER hold funds!
///         Malicious tx payloads could wipe out any funds left here.
contract ExecRequestFacet {
    // solhint-disable-next-line max-line-length
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    uint256 public constant DIAMOND_CALL_OVERHEAD = 33000;

    address public immutable gelato;
    uint256 public immutable chainId;
    bytes32 public immutable domainSeparator;
    address public immutable gelatoRelayerTreasury;

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(
        address _gelato,
        address _gelatoRelayerTreasury,
        string memory _version
    ) {
        gelato = _gelato;

        uint256 _chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }

        chainId = _chainId;

        domainSeparator = keccak256(
            abi.encode(
                keccak256(bytes(EIP712_DOMAIN_TYPE)),
                keccak256(bytes("GelatoRelayer")),
                keccak256(bytes(_version)),
                bytes32(chainId),
                address(this)
            )
        );

        gelatoRelayerTreasury = _gelatoRelayerTreasury;
    }

    function executeRequest(
        uint256 _gasCost,
        Request calldata _req,
        bytes calldata _signature
    ) external onlyGelato returns (uint256 credit) {
        uint256 startGas = gasleft();

        LibExecRequest.verifyDeadline(_req.deadline);

        LibExecRequest.verifyChainId(_req.chainId);

        LibExecRequest.verifyAndIncrementNonce(_req.nonce, _req.from);

        LibExecRequest.verifySignature(domainSeparator, _req, _signature);

        uint256 expectedCredit = _req.feeTokenPriceInNative * _gasCost;

        if (_req.isSelfPayingTx) {
            credit = LibExecRequest.execSelfPayingTx(
                gelato,
                gelatoRelayerTreasury,
                _req
            );
        } else {
            LibExecRequest.execPrepaidTx(gelatoRelayerTreasury, _req);

            credit = expectedCredit;

            if (credit > 0)
                IGelatoRelayerTreasury(gelatoRelayerTreasury).chargeGelatoFee(
                    _req.from,
                    _req.feeToken,
                    credit
                );
        }

        LibExecRequest.verifyGasCost(_gasCost, startGas, DIAMOND_CALL_OVERHEAD);
    }
}
