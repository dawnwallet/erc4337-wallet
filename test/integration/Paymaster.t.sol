// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";
import {IEntryPoint} from "src/external/IEntryPoint.sol";
import {PayMaster} from "src/PayMaster.sol";

contract SmartWalletIntegrationTest is Test {
    SmartWallet wallet;
    PayMaster paymaster;
    uint32 public constant UNSTAKE_DELAY = 1 days;
    uint112 depositAmount = 1 ether;
    uint112 stakeAmount = 2 ether;

    IEntryPoint public constant entryPoint = IEntryPoint(0x602aB3881Ff3Fa8dA60a8F44Cf633e91bA1FdB69);
    address ownerAddress = 0xB8Ce83E0f1Db078d7e9cf3576a05C63195472A56;

    function setUp() public {
        wallet = new SmartWallet(address(entryPoint), ownerAddress);
        paymaster = new PayMaster(address(entryPoint));

        // Stake ETH through paymaster on EntryPoint
        paymaster.addStake{value: stakeAmount}(UNSTAKE_DELAY);

        // Deposit ETH to pay for user transactions
        paymaster.deposit{value: depositAmount}();
    }

    function test_SetupState() public {
        assertEq(address(paymaster.entryPoint()), address(entryPoint));
        assertEq(entryPoint.getDepositInfo(address(paymaster)).staked, true);
        assertEq(entryPoint.balanceOf(address(paymaster)), depositAmount);
        assertEq(entryPoint.getDepositInfo(address(paymaster)).stake, stakeAmount);
    }

    function test_ExecuteUserOp() public {
        // 1.
    }
}
