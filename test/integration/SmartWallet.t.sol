// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";

contract SmartWalletIntegrationTest is Test {
    SmartWallet wallet;

    address public constant ENTRY_POINT = 0x602aB3881Ff3Fa8dA60a8F44Cf633e91bA1FdB69;

    function setUp() public {
        wallet = new SmartWallet(entryPoint, ownerAddress);
    }

    function test_executeUserOp() public {
        // 1.
    }
}
