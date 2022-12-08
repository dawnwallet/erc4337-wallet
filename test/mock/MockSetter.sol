// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract MockSetter {
    uint256 public value;

    function setValue(uint256 _value) public {
        value = _value;
    }
}
