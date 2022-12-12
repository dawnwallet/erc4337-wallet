// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {EllipticCurve} from "src/verifier/EllipticCurve.sol";

contract AppleSigVerifier is EllipticCurve {
    /// @notice Verify an Apple Secure Enclave generated secp256r1 signature
    function verifySignature(bytes32 message, uint256[2] memory signature, uint256[2] memory publicKey)
        external
        pure
        returns (bool)
    {
        return validateSignature(message, signature, publicKey);
    }
}
