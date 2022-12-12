// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Latest configuration of deployed contracts
library GoerliConfig {
    // Goerli chain
    uint256 public constant CHAIN_ID = 5;

    // Account abstraction contracts
    address public constant ENTRY_POINT = 0x9d98Bc2609b080a12aFd52477514DB95d668be3b;
    address public constant PAYMASTER = 0xf18d5c7247b31812d3D06a74Db5CE4A09c12285D;
    address public constant WALLET = 0x1d7dC84343Ae6b068caC1555957ce25513766BD2;
    address public constant BENEFICIARY = 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1;
    address public constant WALLET_FACTORY = 0x2eCf50A78Bc89A3A429d30D8CCD98bCbaF655ff7;

    // Deployer
    address public constant DEPLOYER = 0x604A3a1965b08b00573EcC2AF233437e84de7a86;

    // Owner of wallets
    address public constant WALLET_OWNER = 0xB4c251bf29dEee4E74f128f8B8aAb5b61143F492;
}
