// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";
import {UserOperation} from "../src/UserOperation.sol";
import {MockSetter} from "./mock/MockSetter.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

// Assumes chainId is 0x1, entryPoint is address(0x1). Hardcoded due to Solidity stack too deep errors, tricky to work around
function getUserOperation(address sender, uint256 nonce, bytes memory callData, uint256 ownerPrivateKey, Vm vm)
    returns (UserOperation memory, bytes32)
{
    // Signature is generated over the userOperation, entryPoint and chainId
    bytes memory message = abi.encode(
        sender,
        nonce,
        "", // initCode
        callData,
        1e6, // callGasLimit
        1e6, // verificationGasLimit
        1e6, // preVerificationGas
        1e6, // maxFeePerGas,
        1e6, // maxPriorityFeePerGas,
        "", // paymasterAndData,
        0x1, // entryPoint
        0x1 // chainId
    );
    bytes32 digest = ECDSA.toEthSignedMessageHash(message);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
    bytes memory signature = bytes.concat(r, s, bytes1(v));

    UserOperation memory userOp = UserOperation({
        sender: sender,
        nonce: nonce,
        initCode: "",
        callData: callData,
        callGasLimit: 1e6,
        verificationGasLimit: 1e6,
        preVerificationGas: 1e6,
        maxFeePerGas: 1e6,
        maxPriorityFeePerGas: 1e6,
        paymasterAndData: "",
        signature: signature
    });

    return (userOp, digest);
}

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

    /// @notice Validate that validateUserOp() can be called and wallet state updated
    function test_validateUserOp() public {
        assertEq(wallet.nonce(), 0);
        (UserOperation memory userOp, bytes32 digest) = getUserOperation(
            address(wallet), wallet.nonce(), abi.encodeWithSignature("setValue(uint256)", 1), ownerPrivateKey, vm
        );

        address aggregator = address(0x1);
        uint256 missingWalletFunds = 0;

        vm.prank(entryPoint);
        uint256 deadline = wallet.validateUserOp(userOp, digest, aggregator, missingWalletFunds);
        assertEq(deadline, 0);

        // Validate nonce incremented
        assertEq(wallet.nonce(), 1);
    }

    /// @notice Validate that the entryPoint is prefunded with ETH on validateUserOp()
    function test_validateUserOpFundEntryPoint() public {}

    /// @notice Validate that EntryPoint can call into wallet and execute transactions
    function test_executeFromEntryPoint() public {
        assertEq(mockSetter.value(), 0);
        bytes memory payload = abi.encodeWithSelector(mockSetter.setValue.selector, 1);

        vm.prank(entryPoint);
        wallet.executeFromEntryPoint(address(mockSetter), 0, payload);

        // Verify mock setter contract state updated
        assertEq(mockSetter.value(), 1);
    }
}
