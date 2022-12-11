// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {getUserOpHash} from "test/utils/getUserOpHash.sol";

/// @notice Create a signature over a user operation
function createSignature(UserOperation memory userOp, address entryPoint, uint8 chainId, uint256 ownerPrivateKey, Vm vm)
    pure
    returns (bytes memory)
{
    bytes32 message = getUserOpHash(userOp, entryPoint, chainId);
    bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, messageHash);
    bytes memory signature = bytes.concat(r, s, bytes1(v));
    return signature;
}
