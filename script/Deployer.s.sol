// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {SmartWallet} from "src/SmartWallet.sol";
import {PayMaster} from "src/PayMaster.sol";
import "forge-std/Script.sol";

// Deploy the smart wallet. Make use of a previously deployed ENTRY_POINT
// Note: The Paymaster is setup to pay for all transactions for all users, using ETH
contract Deployer is Script {
    SmartWallet public wallet;
    PayMaster public paymaster;

    address public constant ENTRY_POINT = 0x602aB3881Ff3Fa8dA60a8F44Cf633e91bA1FdB69;
    address public constant OWNER = 0x64c4Bffb220818F0f2ee6DAe7A2F17D92b359c5d;

    uint32 public constant UNSTAKE_DELAY = 1 days;
    uint112 PAYMASTER_DEPOSIT = 0.1 ether;
    uint112 PAYMASTER_STAKE = 0.2 ether;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        wallet = new SmartWallet(ENTRY_POINT, OWNER);
        paymaster = new PayMaster(ENTRY_POINT);

        // Stake ETH through paymaster on EntryPoint
        paymaster.addStake{value: PAYMASTER_STAKE}(UNSTAKE_DELAY);

        // Deposit ETH to pay for user transactions
        paymaster.deposit{value: PAYMASTER_DEPOSIT}();

        vm.stopBroadcast();
    }
}
