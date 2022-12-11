// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {MockSetter} from "./mock/MockSetter.sol";
import {getUserOperation} from "./Fixtures.sol";

contract SmartWalletContractUnitTest is Test {
    SmartWallet wallet;
    MockSetter mockSetter;
    address entryPoint = address(0x1);
    uint256 chainId = block.chainid;
    uint256 ownerPrivateKey = uint256(0x56b861d4f5581b621ed04ac55e4f6f6a739e26c2c71dd1019e9994e3c068cdcf);
    address ownerAddress = 0xB8Ce83E0f1Db078d7e9cf3576a05C63195472A56;

    function setUp() public {
        wallet = new SmartWallet(entryPoint, ownerAddress);
        mockSetter = new MockSetter();

        // Populate smart wallet with ETH to pay for transactions
        vm.deal(address(wallet), 5 ether);
    }

    function test_SetupState() public {
        assertEq(address(wallet.entryPoint()), entryPoint);
        assertEq(wallet.owner(), ownerAddress);
    }

    function test_UpdateEntryPoint() public {
        address newEntryPoint = address(0x2);
        vm.prank(ownerAddress);
        wallet.setEntryPoint(newEntryPoint);
        assertEq(address(wallet.entryPoint()), newEntryPoint);
    }

    function test_UpdateEntryPoint_auth() public {
        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        wallet.setEntryPoint(address(2));
    }

    /// @notice Validate that validateUserOp() can be called and wallet state updated
    function test_ValidateUserOp() public {
        assertEq(wallet.nonce(), 0);
        (UserOperation memory userOp, bytes32 userOpHash) = getUserOperation(
            address(wallet),
            wallet.nonce(),
            abi.encodeWithSignature("setValue(uint256)", 1),
            entryPoint,
            uint8(chainId),
            ownerPrivateKey,
            vm
        );

        uint256 missingWalletFunds = 0;

        address aggregator = address(2);
        vm.prank(entryPoint);
        uint256 deadline = wallet.validateUserOp(userOp, userOpHash, aggregator, missingWalletFunds);
        assertEq(deadline, 0);

        // Validate nonce incremented
        assertEq(wallet.nonce(), 1);
    }

    /// @notice Validate that the entryPoint is prefunded with ETH on validateUserOp()
    function test_ValidateUserOpFundEntryPoint() public {}

    /// @notice Validate that EntryPoint can call into wallet and execute transactions
    function test_ExecuteFromEntryPoint() public {
        assertEq(mockSetter.value(), 0);
        bytes memory payload = abi.encodeWithSelector(mockSetter.setValue.selector, 1);

        vm.prank(entryPoint);
        wallet.executeFromEntryPoint(address(mockSetter), 0, payload);

        // Verify mock setter contract state updated
        assertEq(mockSetter.value(), 1);
    }
}
