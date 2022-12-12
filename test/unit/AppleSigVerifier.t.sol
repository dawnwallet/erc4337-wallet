// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {AppleSigVerifier} from "src/AppleSigVerifier.sol";

contract AppleSigVerifierTest is Test {
    AppleSigVerifier verifier;

    bytes32 message = "TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQ=";
    string publicKey =
        "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEHWnUs/j65AtdhjyHp0h6vWgCsQ1m\rLP/TtyfCcDS63tqKRnXDwE6JiDCJeGPBPwLHLVh3hceZe5yPNgoqPE3BjQ==";

    function setUp() public {
        verifier = new AppleSigVerifier();
    }

    function test_IsOnCurve() public {
        uint256[2] memory signature = [uint256(1), uint256(1)];

        bool result = verifier.isOnCurve(signature);
        assertTrue(result);
    }

    function test_VerifySignature() public {
        bool result = verifier.verifySignature(message, rs, Q);
        assertTrue(result);
    }
}
