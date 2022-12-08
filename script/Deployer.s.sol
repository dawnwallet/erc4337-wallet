// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {SmartWallet} from "../src/SmartWallet.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Deployer is Script {
    SmartWallet public wallet;

    address public constant ENTRY_POINT = 0x90a982662026c5f5B5B2c1dECa0071D61d901fcB;
    address public constant OWNER = 0x64c4Bffb220818F0f2ee6DAe7A2F17D92b359c5d;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        wallet = new SmartWallet(ENTRY_POINT, OWNER);
        console.log("Wallet deployed to: ", address(wallet));
        vm.stopBroadcast();
    }
}
