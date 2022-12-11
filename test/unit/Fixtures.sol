// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {UserOperation} from "src/external/UserOperation.sol";

// Assumes chainId is 0x1, entryPoint is address(0x1). Hardcoded due to Solidity stack too deep errors, tricky to work around
function getUserOperation(address sender, uint256 nonce, bytes memory callData, uint256 ownerPrivateKey, Vm vm)
    pure
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
