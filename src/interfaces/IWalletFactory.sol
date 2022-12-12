// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {SmartWallet} from "src/SmartWallet.sol";

/// @notice IWalletFactory interface
interface IWalletFactory {
    
    /// @notice Deploy a smart wallet, with an entryPoint and Owner specified by the user
    ///         Intended that all wallets are deployed through this factory, so if no initCode is passed
    ///         then just returns the CREATE2 computed address
    function deployWallet(address entryPoint, address walletOwner, uint256 salt)
        external
        returns (SmartWallet);

    /// @notice Deterministically compute the address of a smart wallet using Create2
    function computeAddress(address entryPoint, address walletOwner, uint256 salt) external view returns (address);
}
