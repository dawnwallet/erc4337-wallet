// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {PayMaster} from "./PayMaster.sol";

/// @notice PayMaster that allows a user to pay for transactions using an ERC20 token
/// @dev Only Chainlink oracles should be supported
contract PayMasterToken is PayMaster {
    event AddToken(address indexed _token, address indexed _oracle);
    event RemoveToken(address indexed _token, address indexed _oracle);

    /// @notice Mapping of token to the oracle that provides a price for it in terms of ETH
    mapping(address => address) public tokenToOracle;

    constructor(address _entryPoint) PayMaster(_entryPoint) {}

    /// @notice Get the oracle that provides a price for a token in terms of ETH
    function getTokenOracle(address _token) public view returns (address) {
        return tokenToOracle[_token];
    }

    /// @notice Add a token to be eligible for paying for transactions
    function addToken(address _token, address _oracle) external onlyOwner {
        require(tokenToOracle[_token] == address(0));
        tokenToOracle[_token] = _oracle;
        emit AddToken(_token, _oracle);
    }

    /// @notice Remove a token from the list of eligible tokens for paying for transactions
    function removeToken(address _token) external onlyOwner {
        delete tokenToOracle[_token];
        emit RemoveToken(_token, tokenToOracle[_token]);
    }
}
