// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {PayMasterToken} from "src/PayMasterToken.sol";
import {GoerliConfig} from "config/GoerliConfig.sol";
import "forge-std/Script.sol";

// Deploy the smart wallet. Make use of a previously deployed ENTRY_POINT
contract DeployPayMasterToken is Script {
    PayMasterToken public paymaster;

    address public constant ENTRY_POINT = GoerliConfig.ENTRY_POINT;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        paymaster = new PayMasterToken(ENTRY_POINT);
        vm.stopBroadcast();
    }
}
