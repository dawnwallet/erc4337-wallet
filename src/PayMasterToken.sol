// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {PayMaster} from "./PayMaster.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @notice PayMaster that allows a user to pay for transactions using an ERC20 token
/// @dev Only Chainlink oracles should be supported
contract PayMasterToken is PayMaster, Pausable {
    using SafeERC20 for IERC20;

    event AddToken(address indexed token, address indexed oracle);
    event RemoveToken(address indexed token, address indexed oracle);
    event Deposit(address indexed token, address indexed from, uint256 amount);
    event Withdraw(address indexed token, address indexed to, uint256 amount);
    event EmergencyWithdraw(address indexed token, address indexed to, uint256 amount);

    /// @notice Mapping of token to the oracle that provides a price for it in terms of ETH
    mapping(address => address) public tokenToOracle;

    /// @notice Mapping of token to user to balance
    mapping(address => mapping(address => uint256)) public tokenBalances;

    constructor(address _entryPoint) PayMaster(_entryPoint) Pausable() {}

    /// @notice Get the balance of a token for a user
    function getBalance(address token, address user) public view returns (uint256) {
        return tokenBalances[token][user];
    }

    /// @notice Get the oracle that provides a price for a token in terms of ETH
    function getTokenOracle(address token) public view returns (address) {
        return tokenToOracle[token];
    }

    /// @notice Add a token to be eligible for paying for transactions
    function addToken(address token, address oracle) external onlyOwner {
        require(tokenToOracle[token] == address(0));
        tokenToOracle[token] = oracle;
        emit AddToken(token, oracle);
    }

    /// @notice Remove a token from the list of eligible tokens for paying for transactions
    function removeToken(address token) external onlyOwner {
        delete tokenToOracle[token];
        emit RemoveToken(token, tokenToOracle[token]);
    }

    /// @notice Deposit ERC20 tokens, which can be used to pay for transactions
    function deposit(address token, uint256 amount) external {
        // checks
        require(tokenToOracle[token] != address(0), "Unsupported token");

        // effects
        tokenBalances[token][msg.sender] += amount;

        // interactions
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(token, msg.sender, amount);
    }

    /// @notice Withdraw ERC20 tokens, that were being used to pay for transactions
    function withdrawToken(address token, uint256 amount) external {
        _withdraw(token, msg.sender, amount);
        emit Withdraw(token, msg.sender, amount);
    }

    /// @notice Only owner emergency withdraw of tokens
    function emergencyWithdraw(address token, address user, uint256 amount) external onlyOwner {
        _withdraw(token, user, amount);
        emit EmergencyWithdraw(token, owner(), amount);
    }

    /// @notice Internal withdraw method
    function _withdraw(address token, address user, uint256 amount) internal {
        require(tokenToOracle[token] != address(0), "Unsupported token");
        uint256 userBalance = tokenBalances[token][user];
        require(userBalance >= amount, "Insufficient balance");
        tokenBalances[token][user] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
