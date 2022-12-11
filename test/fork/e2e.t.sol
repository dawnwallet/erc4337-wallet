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
        userOp = UserOperation({
            sender: GoerliConfig.WALLET,
            nonce: wallet.nonce(),
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
            signature: ""
        });
        bytes memory signature =
            createSignature(userOp, address(entryPoint), GoerliConfig.CHAIN_ID, ownerPrivateKey, vm);
        userOp.signature = signature;

        userOpHash = getUserOpHash(userOp, address(entryPoint), GoerliConfig.CHAIN_ID);
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
