// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";
import {UserOperation} from "../src/UserOperation.sol";
import {MockSetter} from "./mock/MockSetter.sol";

contract SmartWalletContract is Test {
    SmartWallet wallet;
    MockSetter mockSetter;
    address entryPoint = address(0x1);
    uint256 ownerPrivateKey = uint256(0x56b861d4f5581b621ed04ac55e4f6f6a739e26c2c71dd1019e9994e3c068cdcf);
    address ownerAddress = 0xB8Ce83E0f1Db078d7e9cf3576a05C63195472A56;

    function setUp() public {
        wallet = new SmartWallet(entryPoint, ownerAddress);
        mockSetter = new MockSetter();

        // Populate smart wallet with ETH to pay for transactions
        vm.deal(address(wallet), 5 ether);
    }

    function test_SetupState() public {
        assertEq(wallet.entryPoint(), entryPoint);
        assertEq(wallet.owner(), ownerAddress);
    }

    function test_updateEntryPoint() public {
        address newEntryPoint = address(0x2);
        vm.prank(ownerAddress);
        wallet.setEntryPoint(newEntryPoint);
        assertEq(wallet.entryPoint(), newEntryPoint);
    }

    function test_updateEntryPoint_auth() public {
        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        wallet.setEntryPoint(address(2));
    }

    // TODO
    /// @notice Validate that validateUserOp() can be called and wallet state updated
    function test_validateUserOp() public {
        bytes memory payload = abi.encodeWithSignature("setValue(uint256)", 1);

        // TODO: Generate signature over relevant data and add to payload
        UserOperation memory userOp = UserOperation({
            sender: address(wallet),
            nonce: wallet.nonce(),
            initCode: "",
            callData: payload,
            callGasLimit: 1e6,
            verificationGasLimit: 1e6,
            preVerificationGas: 1e6,
            maxFeePerGas: 1e6,
            maxPriorityFeePerGas: 1e6,
            paymasterAndData: "",
            signature: ""
        });

        address aggregator = address(0x1);
        uint256 missingWalletFunds = 5e6;
        bool result = wallet.validateUserOp(userOp, keccak256(payload), aggregator, missingWalletFunds);
        assertTrue(result);
    }

    /// @notice Validate that EntryPoint can call into wallet and execute transactions
    function test_executeFromEntryPoint() public {
        assertEq(mockSetter.value(), 0);
        bytes memory payload = abi.encodeWithSelector(mockSetter.setValue.selector, 1);

        vm.prank(entryPoint);
        wallet.executeFromEntryPoint(address(mockSetter), 0, payload);

        // Verify mock setter contract state updated
        assertEq(mockSetter.value(), 1);
    }

    function test_updateEntryPoint_nonce() public {}
}
