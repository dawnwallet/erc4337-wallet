// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";

contract SmartWalletContract is Test {
    SmartWallet wallet;
    address entryPoint = address(0x1);

    function setUp() public {
        wallet = new SmartWallet(entryPoint);
    }

    function test_SetupState() public {
        assertEq(wallet.entryPoint(), entryPoint);
    }
}
