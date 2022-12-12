// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {IEntryPoint} from "src/external/IEntryPoint.sol";
import {IWallet} from "src/interfaces/IWallet.sol";
import {IPayMaster} from "src/interfaces/IPayMaster.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {GoerliConfig} from "config/GoerliConfig.sol";
import {createSignature} from "test/utils/createSignature.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";
import {MockERC20} from "test/unit/mock/MockERC20.sol";

/// @notice End-to-end test deployed account abstraction contracts
contract EndToEndTestNoPaymaster is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(GoerliConfig.ENTRY_POINT);
    IWallet public constant wallet = IWallet(GoerliConfig.WALLET);
    IPayMaster public constant paymaster = IPayMaster(GoerliConfig.PAYMASTER);
    address payable public beneficiary = payable(GoerliConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");

    MockERC20 public token;

    // Test case
    bytes32 public userOpHash;
    address aggregator;
    uint256 missingWalletFunds;
    address recipient = 0x7851b240aCE79FA6961AE36c865802D1416611e7;
    uint256 tokenTransferAmount;

    UserOperation public userOp;

    function setUp() public {
        // 1. Deploy a MockERC20 and fund smart wallet with tokens
        token = new MockERC20();
        token.mint(address(wallet), 100);

        // 2. Generate a userOperation
        // UserOperation callData transfers a small amount of ETH to 0x7851b240ace79fa6961ae36c865802d1416611e7
        userOp = UserOperation({
            sender: GoerliConfig.WALLET,
            nonce: wallet.nonce(),
            initCode: "",
            callData: "",
            callGasLimit: 70_000,
            verificationGasLimit: 958666,
            preVerificationGas: 115256,
            maxFeePerGas: 1000105660,
            maxPriorityFeePerGas: 1000000000,
            paymasterAndData: "",
            signature: ""
        });

        // Encode userOperation transfer
        tokenTransferAmount = 10;
        userOp.callData = abi.encodeWithSelector(
            wallet.executeFromEntryPoint.selector,
            address(token), // target
            0, // value
            abi.encodeWithSelector(token.transfer.selector, recipient, tokenTransferAmount) // callData
        );

        // Sign userOperation and attach signature
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
        userOp.signature = signature;

        // Set remainder of test case
        aggregator = address(0);
        missingWalletFunds = 1096029019333521;

        // 3. Fund wallet with ETH
        vm.deal(address(wallet), 5 ether);
    }

    /// @notice Validate that the smart wallet can validate a userOperation
    function test_WalletValidateUserOp() public {
        vm.prank(address(entryPoint));
        wallet.validateUserOp(userOp, userOpHash, aggregator, missingWalletFunds);
    }

    /// @notice Validate that the EntryPoint can execute a userOperation.
    ///         No Paymaster, smart wallet pays for gas
    function test_HandleOps_NoPaymaster() public {
        // The calldata sent to the wallet is actually reverting
        uint256 initialRecipientBalance = token.balanceOf(recipient);
        uint256 initialWalletBalance = token.balanceOf(address(wallet));
        uint256 initialWalletEthBalance = address(wallet).balance;

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entryPoint.handleOps(userOps, beneficiary);

        // 1. Verify token transfer
        uint256 finalRecipientBalance = token.balanceOf(recipient);
        uint256 recipientGain = finalRecipientBalance - initialRecipientBalance;

        uint256 finalWalletBalance = token.balanceOf(address(wallet));
        uint256 walletLoss = initialWalletBalance - finalWalletBalance;

        // Verify recipient received tokens from smart wallet
        assertEq(recipientGain, tokenTransferAmount);
        console.log("recipientGain:", recipientGain);

        // Verify wallet lost tokens
        assertEq(walletLoss, tokenTransferAmount);
        console.log("wallet loss: ", walletLoss);

        // 2. Verify smart wallet paid for gas
        uint256 walletEthLoss = initialWalletEthBalance - address(wallet).balance;
        console.log("wallet eth loss: ", walletEthLoss);
        assertGt(walletEthLoss, 0);
    }
}
