// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";

/// @notice Create a signature over a user operation
function createSignature(
    UserOperation memory userOp,
    bytes32 messageHash, // in form of ECDSA.toEthSignedMessageHash
    uint256 ownerPrivateKey,
    Vm vm
) pure returns (bytes memory) {
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
    bytes memory signature = bytes.concat(r, s, bytes1(v));
    return signature;
}
