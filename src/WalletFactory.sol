// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {SmartWallet} from "src/SmartWallet.sol";
import {IEntryPoint} from "src/external/IEntryPoint.sol";
import {IWalletFactory} from "src/interfaces/IWalletFactory.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Create2} from "openzeppelin-contracts/utils/Create2.sol";

/// @notice Factory contract to deploy user smart wallets. Expected to be passed the bytecode of the user
///         smart wallet
contract WalletFactory is IWalletFactory, Ownable, Pausable {
    constructor() Ownable() Pausable() {}

    /// @notice Pause the WalletFactory to prevent new wallet creation. OnlyOwner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause the WalletFactory to allow new wallet creation. OnlyOwner
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Deploy a smart wallet, with an entryPoint and Owner specified by the user
    ///         Intended that all wallets are deployed through this factory, so if no initCode is passed
    ///         then just returns the CREATE2 computed address
    function deployWallet(address entryPoint, address walletOwner, uint256 salt)
        external
        override
        returns (SmartWallet)
    {
        address walletAddress = computeAddress(entryPoint, walletOwner, salt);

        // Determine if a wallet is already deployed at this address, if so return that
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return SmartWallet(payable(walletAddress));
        } else {
            // Deploy the wallet
            SmartWallet wallet = new SmartWallet{salt: bytes32(salt)}(entryPoint, walletOwner);
            return wallet;
        }
    }

    /// @notice Deterministically compute the address of a smart wallet using Create2
    function computeAddress(address entryPoint, address walletOwner, uint256 salt)
        public
        view
        override
        returns (address)
    {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(abi.encodePacked(type(SmartWallet).creationCode, abi.encode(entryPoint, walletOwner)))
        );
    }
}
