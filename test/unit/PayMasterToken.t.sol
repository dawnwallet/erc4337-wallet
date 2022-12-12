// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {PayMasterToken} from "src/PayMasterToken.sol";
import {MockERC20} from "./mock/MockERC20.sol";

import "forge-std/Test.sol";

contract PayMasterTokenUnitTest is Test {
    PayMasterToken paymaster;
    MockERC20 token;

    address entryPoint = address(1);
    address oracle = address(2);

    function setUp() public {
        paymaster = new PayMasterToken(entryPoint);
        token = new MockERC20();
    }

    function test_AddToken() public {
        paymaster.addToken(address(token), oracle);
        assertEq(paymaster.tokenToOracle(address(token)), oracle);
        assertEq(paymaster.getTokenOracle(address(token)), oracle);
    }

    function test_RemoveToken() public {
        paymaster.addToken(address(token), oracle);
        paymaster.removeToken(address(token));
        assertEq(paymaster.getTokenOracle(address(token)), address(0));
    }
}
