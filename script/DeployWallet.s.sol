// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {SmartWallet} from "src/SmartWallet.sol";
import "forge-std/Script.sol";

// Deploy the smart wallet. Make use of a previously deployed ENTRY_POINT
contract DeployWallet is Script {
    SmartWallet public wallet;

    address public constant ENTRY_POINT = 0x602aB3881Ff3Fa8dA60a8F44Cf633e91bA1FdB69;
    address public constant OWNER = 0xB4c251bf29dEee4E74f128f8B8aAb5b61143F492;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        wallet = new SmartWallet(ENTRY_POINT, OWNER);

        // Transfer some ETH to the wallet
        payable(address(wallet)).transfer(0.1 ether);
        vm.stopBroadcast();
    }
}
