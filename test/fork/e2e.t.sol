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

/// @notice End-to-end test deployed account abstraction contracts
contract EndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(GoerliConfig.ENTRY_POINT);
    IWallet public constant wallet = IWallet(GoerliConfig.WALLET);
    IPaymaster public constant paymaster = IPaymaster(GoerliConfig.PAYMASTER);
    address payable public beneficiary = payable(GoerliConfig.BENEFICIARY);
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Test case
    bytes32 public userOpHash;
    address aggregator;
    uint256 missingWalletFunds;

    UserOperation public userOp;

    function setUp() public {
        // UserOperation callData transfers a small amount of ETH to 0x7851b240ace79fa6961ae36c865802d1416611e7
        userOp = UserOperation({
            sender: GoerliConfig.WALLET,
            nonce: wallet.nonce(),
            initCode: "",
            callData: bytes(
                "0x80c5c7d00000000000000000000000007851b240ace79fa6961ae36c865802d1416611e70000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000078"
                ),
            callGasLimit: 70_000,
            verificationGasLimit: 958666,
            preVerificationGas: 115256,
            maxFeePerGas: 1000105660,
            maxPriorityFeePerGas: 1000000000,
            paymasterAndData: "",
            signature: ""
        });
        userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);

        userOp.signature = signature;
        aggregator = address(0);
        missingWalletFunds = 1096029019333521;
    }

    /// @notice Validate that the smart wallet can validate a userOperation
    function test_WalletValidateUserOp() public {
        // userOpHash, aggregator, missingWalletFunds
        // 0x4a63534b28f26d5ea51bea9b18283801065ead2f0d7f92e25bfe1e8f26b11ec8, 0x0000000000000000000000000000000000000000, 1096029019333521
        vm.prank(address(entryPoint));
        wallet.validateUserOp(userOp, userOpHash, aggregator, missingWalletFunds);
    }

    /// @notice Validate that the EntryPoint can execute a userOperation.
    ///         No Paymaster, smart wallet pays for gas
    function test_HandleOps_NoPaymaster() public {
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entryPoint.handleOps(userOps, beneficiary);
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
