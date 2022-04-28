// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {GelatoMetaBoxBase} from "./base/GelatoMetaBoxBase.sol";
import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {MetaTxRequest} from "./structs/RequestTypes.sol";
import {GelatoTokenUtils} from "./gelato/GelatoTokenUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GelatoMetaBoxPullFee is GelatoMetaBoxBase, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable gelato;
    uint256 public immutable chainId;

    mapping(address => uint256) public nonce;
    EnumerableSet.AddressSet private _whitelistedDest;

    event LogMetaTxRequestPullFee(
        address indexed sponsor,
        address indexed user,
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) Ownable() Pausable() {
        gelato = _gelato;

        uint256 _chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }

        chainId = _chainId;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function whitelistDest(address _dest) external onlyOwner {
        require(
            !_whitelistedDest.contains(_dest),
            "Destination address already whitelisted"
        );

        _whitelistedDest.add(_dest);
    }

    function delistDest(address _dest) external onlyOwner {
        require(
            _whitelistedDest.contains(_dest),
            "Destination address not whitelisted"
        );

        _whitelistedDest.remove(_dest);
    }

    /// @notice Relay meta tx request + pull fee from (transferFrom) _req.sponsor's address
    /// @dev    Assumes that _req.sponsor has approved this contract to spend _req.feeToken
    /// @param _req Relay request data
    /// @param _userSignature EIP-712 compliant signature from _req.user
    /// @param _sponsorSignature EIP-712 compliant signature from _req.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    /// @notice Handles the case of tokens with fee on transfer
    /// @param _taskId Gelato task id
    // solhint-disable-next-line function-max-lines
    function metaTxRequestPullFee(
        MetaTxRequest calldata _req,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        require(
            // solhint-disable-next-line not-rely-on-time
            _req.deadline == 0 || _req.deadline >= block.timestamp,
            "Request expired"
        );

        require(_req.chainId == chainId, "Wrong chainId");

        require(_req.paymentType == 3, "paymentType must be 3");

        require(
            _whitelistedDest.contains(_req.target),
            "target address not whitelisted"
        );

        require(
            _req.feeToken != NATIVE_TOKEN,
            "Native token not supported for paymentType 3"
        );

        require(_gelatoFee <= _req.maxFee, "Executor over-charged");

        // Verify and increment user's nonce
        uint256 userNonce = nonce[_req.user];
        require(_req.nonce == userNonce, "Invalid nonce");
        nonce[_req.user] = userNonce + 1;

        _verifyMetaTxRequestSignature(_req, _userSignature, _req.user);
        // If is sponsored tx, we also verify sponsor's signature
        if (_req.user != _req.sponsor) {
            _verifyMetaTxRequestSignature(
                _req,
                _sponsorSignature,
                _req.sponsor
            );
        }

        {
            require(_isContract(_req.target), "Cannot call EOA");
            (bool success, ) = _req.target.call(
                _req.isEIP2771
                    ? abi.encodePacked(_req.data, _req.user)
                    : _req.data
            );
            require(success, "External call failed");
        }

        SafeERC20.safeTransferFrom(
            IERC20(_req.feeToken),
            _req.sponsor,
            gelato,
            _gelatoFee
        );

        emit LogMetaTxRequestPullFee(
            _req.sponsor,
            _req.user,
            _req.target,
            _req.feeToken,
            _gelatoFee,
            _taskId
        );
    }

    function getWhitelistedDest() external view returns (address[] memory) {
        uint256 length = _whitelistedDest.length();
        address[] memory addresses = new address[](length);

        for (uint256 i; i < length; i++) {
            addresses[i] = _whitelistedDest.at(i);
        }

        return addresses;
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _getDomainSeparator(chainId);
    }
}
