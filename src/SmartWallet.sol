// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IAccount} from "src/external/IAccount.sol";
import {IEntryPoint} from "src/external/IEntryPoint.sol";
import {UserOperation} from "src/external/UserOperation.sol";

import "forge-std/console.sol";

/// @notice Smart contract wallet compatible with ERC-4337
// Wallet features:
// 1. Updateable entrypoint
// 2. Nonce for replay detection
// 3. ECDSA for signature validation
// In this early version, there is an owner/admin who is able to sweep the wallet in case of emergency
// Owner is default set to the deployer address
contract SmartWallet is Ownable, IAccount {
    event UpdateEntryPoint(address indexed _newEntryPoint, address indexed _oldEntryPoint);
    event WithdrawERC20(address indexed _to, address _token, uint256 _amount);
    event PayPrefund(address indexed _payee, uint256 _amount);

    /// @notice EntryPoint contract in the ERC-4337 architecture
    IEntryPoint public entryPoint;

    /// @notice Nonce used for replay protection
    uint256 public nonce;

    /// @notice Validate that only the entryPoint is able to call a method
    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "SmartWallet: Only entryPoint can call this method");
        _;
    }

    /// @notice Able to receive ETH
    receive() external payable {}

    constructor(address _entryPoint, address _owner) Ownable() {
        entryPoint = IEntryPoint(_entryPoint);
        transferOwnership(_owner);
    }

    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        emit UpdateEntryPoint(_newEntryPoint, address(entryPoint));
        entryPoint = IEntryPoint(_newEntryPoint);
    }

    /// @notice Validate that the userOperation is valid. Requirements:
    // 1. Only calleable by EntryPoint
    // 2. Signature is that of the contract owner
    // 3. Nonce is correct
    /// @param userOp - ERC-4337 User Operation
    /// @param userOpHash - Hash of the user operation, entryPoint address and chainId
    /// @param aggregator - Signature aggregator
    /// @param missingWalletFunds - Amount of ETH to pay the EntryPoint for processing the transaction
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash, // TODO: Shouldn't this hash be constructed internally over the userOp? Why is it passed?
        address aggregator,
        uint256 missingWalletFunds
    ) external override onlyEntryPoint returns (uint256 deadline) {
        // Validate signature
        _validateSignature(userOp, userOpHash);

        // TODO: Verify this is correct
        // UserOp may have initCode to deploy a wallet, in which case do not validate the nonce. Used in accountCreation
        if (userOp.initCode.length == 0) {
            // Validate nonce is correct - protect against replay attacks
            uint256 currentNonce = nonce;
            require(currentNonce == userOp.nonce, "SmartWallet: Invalid nonce");

            // Effects
            // Increment nonce
            _updateNonce();
        }

        // Interactions
        _prefundEntryPoint(missingWalletFunds);
        return 0;
    }

    /// @notice Method called by entryPoint to execute the calldata supplied by a wallet
    // TODO: Add a batch execute method?
    /// @param target - Address to send calldata payload for execution
    /// @param value - Amount of ETH to forward to target
    /// @param payload - Calldata to send to target for execution
    function executeFromEntryPoint(address target, uint256 value, bytes calldata payload) external onlyEntryPoint {
        string memory errorMessage = "SmartWallet: call reverted without message";
        (bool success, bytes memory returndata) = target.call{value: value}(payload);
        Address.verifyCallResult(success, returndata, errorMessage);
    }

    /// EMERGENCY RECOVERY
    /// @notice Withdraw ERC20 tokens from the wallet. Permissioned to only the owner
    function withdrawERC20(address token, address to, uint256 amount) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        emit WithdrawERC20(to, token, amount);
    }

    /// @notice Withdraw ETH from the wallet. Permissioned to only the owner
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /////////////////  INTERNAL METHODS ///////////////

    /// @notice Validate the signature of the userOperation
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal view {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(messageHash, userOp.signature);
        require(signer == owner(), "SmartWallet: Invalid signature");
    }

    /// @notice Pay the EntryPoint in ETH ahead of time for the transaction that it will execute
    ///         Amount to pay may be zero, if the entryPoint has sufficient funds or if a paymaster is used
    ///         to pay the entryPoint through other means
    /// @param amount - Amount of ETH to pay the entryPoint
    function _prefundEntryPoint(uint256 amount) internal onlyEntryPoint {
        if (amount == 0) {
            return;
        }

        (bool success,) = payable(address(entryPoint)).call{value: amount}("");
        require(success, "SmartWallet: ETH entrypoint payment failed");
        emit PayPrefund(address(this), amount);
    }

    /// @notice Update the nonce storage variable
    function _updateNonce() internal {
        nonce++;
    }
}
