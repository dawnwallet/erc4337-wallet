// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {createSignature} from "test/utils/createSignature.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";

// Assumes chainId is 0x1, entryPoint is address(0x1). Hardcoded due to Solidity stack too deep errors, tricky to work around
function getUserOperation(
    address sender,
    uint256 nonce,
    bytes memory callData,
    address entryPoint,
    uint8 chainId,
    uint256 ownerPrivateKey,
    Vm vm
) pure returns (UserOperation memory, bytes32) {
    UserOperation memory userOp = UserOperation({
        sender: sender,
        nonce: nonce,
        initCode: "",
        callData: callData,
        callGasLimit: 22017,
        verificationGasLimit: 958666,
        preVerificationGas: 115256,
        maxFeePerGas: 1000105660,
        maxPriorityFeePerGas: 1000000000,
        paymasterAndData: "",
        signature: ""
    });
    bytes32 userOpHash = getUserOpHash(userOp, entryPoint, chainId);
    bytes memory signature = createSignature(userOp, userOpHash, ownerPrivateKey, vm);
    userOp.signature = signature;

    return (userOp, userOpHash);
}
