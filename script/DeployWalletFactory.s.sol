// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {WalletFactory} from "src/WalletFactory.sol";
import {GoerliConfig} from "config/GoerliConfig.sol";
import "forge-std/Script.sol";

// Deploy a WalletFactory, which is used to deploy other smart wallets
contract DeployWalletFactory is Script {
    WalletFactory public factory;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        factory = new WalletFactory();
        vm.stopBroadcast();
    }
}
