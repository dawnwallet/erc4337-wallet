// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";
import {IEntryPoint} from "src/interfaces/IEntryPoint.sol";
import {DepositInfo} from "src/";
import {DepositPaymaster} from "account-abstraction/samples/DepositPaymaster.sol";

contract SmartWalletIntegrationTest is Test {
    SmartWallet wallet;
    DepositPaymaster paymaster;
    uint256 public constant UNSTAKE_DELAY = 1 days;
    uint256 depositAmount = 1 ether;

    IEntryPoint public constant entryPoint = IEntryPoint(0x602aB3881Ff3Fa8dA60a8F44Cf633e91bA1FdB69);

    function setUp() public {
        wallet = new SmartWallet(address(entryPoint), ownerAddress);
        paymaster = new DepositPaymaster(address(entryPoint));

        // Stake ETH through paymaster on EntryPoint
        paymaster.addStake(UNSTAKE_DELAY);

        // Deposit ETH to pay for user transactions
        paymaster.deposit{value: depositAmount}();
    }

    function test_SetupState() public {
        assertEq(paymaster.entryPoint(), address(entryPoint));
        assertEq(entryPoint.balanceOf(address(paymaster)), depositAmount);

        DepositInfo memory depositInfo = entryPoint.getDepositInfo(address(paymaster));
    }

    function test_ExecuteUserOp() public {
        // 1.
    }
}
