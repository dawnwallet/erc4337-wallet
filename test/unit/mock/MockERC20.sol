// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MCT") {}

    function mint(address account, uint256 amount) public returns (bool) {
        _mint(account, amount);
        return true;
    }
}
