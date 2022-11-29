// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IWallet} from "./IWallet.sol";
import {UserOperation} from "./UserOperation.sol";
import {Ownable} from "";

/// @notice Smart contract wallet compatible with ERC-4337

// Wallet features:
// 1. Updateable entrypoint
// 2. Nonce for replay detection
// 3. ECDSA for signature validation
contract SmartWallet is IWallet {

    event UpdateEntryPoint(address indexed _newEntryPoint, address indexed _oldEntryPoint);

    /// @notice Constant ENTRY_POINT contract in ERC-4337 system
    address immutable entryPoint;

    /// @notice Nonce used for replay protection
    uint256 _nonce;

    constructor(address _entryPoint) {
        entryPoint = _entryPoint;
    }

    /// @notice Getter for the nonce on the wallet
    function nonce() external view returns (uint256) {
        return _nonce;
    }

    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        emit UpdateEntryPoint(_newEntryPoint, entryPoint);
        entryPoint = _newEntryPoint;
    }

    /// @notice Validate that a userOperation is valid, required to implement ERC-4337
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address aggregator,
        uint256 missingAccountFund
    ) external override returns (uint256 deadline) {
    
    }
 }
