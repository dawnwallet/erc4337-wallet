// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {IEntryPoint} from "src/external/IEntryPoint.sol";
import {IWallet} from "src/interfaces/IWallet.sol";
import {IPaymaster} from "src/external/IPaymaster.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {GoerliConfig} from "config/GoerliConfig.sol";
import {createSignature} from "test/utils/createSignature.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";
import {MockERC20} from "test/unit/mock/MockERC20.sol";

/// @notice End-to-end test deployed account abstraction contracts
contract EndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(GoerliConfig.ENTRY_POINT);
    IWallet public constant wallet = IWallet(GoerliConfig.WALLET);
    IPaymaster public constant paymaster = IPaymaster(GoerliConfig.PAYMASTER);
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

    // Ideally, mint some ERC20s. Then encode transfers of those

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

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entryPoint.handleOps(userOps, beneficiary);

        // Verify ETH transfer
        uint256 finalRecipientBalance = token.balanceOf(recipient);
        uint256 recipientGain = finalRecipientBalance - initialRecipientBalance;

        uint256 finalWalletBalance = token.balanceOf(address(wallet));
        uint256 walletLoss = initialWalletBalance - finalWalletBalance;

        // Verify recipient received expected ETH transfer from smart wallet
        assertEq(recipientGain, tokenTransferAmount);

        // Verify smart wallet ETH balance decremented by at least the ETH transfer to recipient
        // Wallet has transferred ETH to the recipient and also paid gas
        assertEq(walletLoss, tokenTransferAmount);
    }

    /// @notice Validate that the EntryPoint can execute a userOperation, with the paymaster paying for gas
    function test_HandleOps_Paymaster() public {
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Set the paymaster
        userOp.paymasterAndData = abi.encode(paymaster, bytes(""));
        console.log("paymaster");
        console.logBytes(userOp.paymasterAndData);
        entryPoint.handleOps(userOps, beneficiary);
    }
}
