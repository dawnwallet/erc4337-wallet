// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {IEntryPoint} from "src/external/IEntryPoint.sol";
import {IAccount} from "src/external/IAccount.sol";
import {IPaymaster} from "src/external/IPaymaster.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {GoerliAddresses} from "config/GoerliAddresses.sol";

contract EndToEndTest is Test {
    IEntryPoint public constant entryPoint = IEntryPoint(GoerliAddresses.ENTRY_POINT);
    IAccount public constant wallet = IAccount(GoerliAddresses.WALLET);
    IPaymaster public constant paymaster = IPaymaster(GoerliAddresses.PAYMASTER);

    address payable public beneficiary = payable(GoerliAddresses.BENEFICIARY);

    // Test case
    bytes32 public userOpHash;
    address aggregator;
    uint256 missingWalletFunds;

    UserOperation public userOp;

    function setUp() public {
        userOp = UserOperation({
            sender: GoerliAddresses.WALLET,
            nonce: 0,
            initCode: "",
            callData: bytes(
                "0x80c5c7d00000000000000000000000007851b240ace79fa6961ae36c865802d1416611e70000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000078"
                ),
            callGasLimit: 22017,
            verificationGasLimit: 958666,
            preVerificationGas: 115256,
            maxFeePerGas: 1000105660,
            maxPriorityFeePerGas: 1000000000,
            paymasterAndData: "",
            signature: bytes(
                "0xa8b5c50c7194e83a435aa785abd16dabec108c7d28767d19f9da7b7bc1a6ff0a66e907a0518fb232a01303d0570bc1579e5699e989673cc5585297249f2a23451c"
                )
        });
        userOpHash = 0xa233b17851120b6c41abe27b602ad7d37df3ab03cd723d9e0a41daa313c480bd;
        aggregator = address(0);
        missingWalletFunds = 1096029019333521;
    }

    function test_WalletValidateUserOp() public {
        vm.prank(address(entryPoint));
        wallet.validateUserOp(userOp, userOpHash, aggregator, missingWalletFunds);
    }

    function test_HandleOps() public {
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entryPoint.handleOps(userOps, beneficiary);
    }
}
