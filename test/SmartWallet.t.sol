// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";

contract SmartWalletContract is Test {
    SmartWallet wallet;

    function setUp() public {
        wallet = new SmartWallet();
    }

    function test_SetupState() public {
        assertEq(wallet.ENTRY_POINT(), 0x64c4Bffb220818F0f2ee6DAe7A2F17D92b359c5d);
    }
}
