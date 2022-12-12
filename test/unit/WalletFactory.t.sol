// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {WalletFactory} from "src/WalletFactory.sol";
import {SmartWallet} from "src/SmartWallet.sol";

contract WalletFactoryTest is Test {
    WalletFactory factory;

    address entryPoint = address(0x2);
    address walletOwner = address(0x3);
    uint256 salt = 0x4;

    function setUp() public {
        factory = new WalletFactory();
    }

    function test_DeployWallet() public {
        SmartWallet wallet = factory.deployWallet(entryPoint, walletOwner, salt);

        address computedWalletAddress = factory.computeAddress(entryPoint, walletOwner, salt);
        assertEq(address(wallet), computedWalletAddress);
        assertEq(address(wallet.entryPoint()), entryPoint);
        assertEq(wallet.owner(), walletOwner);
    }
}
