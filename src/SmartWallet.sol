// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IWallet} from "./IWallet.sol";
import {UserOperation} from "./UserOperation.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @notice Smart contract wallet compatible with ERC-4337

// Wallet features:
// 1. Updateable entrypoint
// 2. Nonce for replay detection
// 3. ECDSA for signature validation

// In this early version, there is an owner/admin who is able to sweep the wallet in case of emergency
// Owner is default set to the deployer address
contract SmartWallet is Ownable, IWallet {

    event UpdateEntryPoint(address indexed _newEntryPoint, address indexed _oldEntryPoint);
    event WithdrawERC20(address indexed _to, address _token, uint256 _amount);

    /// @notice Constant ENTRY_POINT contract in ERC-4337 system
    address public entryPoint;

    /// @notice Nonce used for replay protection
    uint256 public nonce;

    /// @notice Able to receive ETH
    receive() external payable {}

    constructor(address _entryPoint) Ownable() {
        entryPoint = _entryPoint;
    }


    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        emit UpdateEntryPoint(_newEntryPoint, entryPoint);
        entryPoint = _newEntryPoint;
    }

    /// @notice Validate that the userOperation is valid. Requirements:
    // 1. Only calleable by EntryPoint
    // 2. Signature is that of the contract owner
    // 3. Nonce is correct
    /// @param userOp - ERC-4337 User Operation
    /// @param userOpHash - Hash of the user operation, entryPoint address and chainId
    /// @param aggregator - 
    /// @param missingWalletFunds - Hash of the user operation
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash, // TODO: Shouldn't this hash be constructed internally over the userOp? Why is it passed?
        address aggregator,
        uint256 missingWalletFunds
    ) external override returns (uint256 deadline) {
        // Validate entryPoint is sender
        require(msg.sender == entryPoint, "SmartWallet: Only entryPoint can validate userOp");
        
        // Validate nonce is correct - protect against replay attacks
        uint256 currentNonce = nonce;
        require(currentNonce == userOp.nonce, "SmartWallet: Invalid nonce");

        // Validate signature
        _validateSignature(userOp, userOpHash);
        
        // Effects
        // Increment nonce
        _updateNonce();
        // Interactions
    }

    /// @notice Method called by entryPoint to execute the calldata supplied by a wallet
    function executeFromEntryPoint() external {

    }

    /// EMERGENCY RECOVERY
    /// @notice Withdraw ERC20 tokens from the wallet. Permissioned to only the owner
    function withdrawERC20(
      address token, 
      address to, 
      uint256 amount
    ) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        emit WithdrawERC20(to, token, amount);
    }

    /////////////////  INTERNAL METHODS ///////////////

    /// @notice Validate the signature of the userOperation
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal {
        // Validate signature
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(messageHash, userOp.signature);
        require(signer == owner(), "SmartWallet: Invalid signature");
    }

    /// @notice Update the nonce storage variable
    function _updateNonce() internal {
        nonce++;
    }
 }
