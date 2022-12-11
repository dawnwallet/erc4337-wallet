// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IPaymaster} from "src/external/IPayMaster.sol";
import {IEntryPoint} from "src/external/IEntryPoint.sol";
import {UserOperation} from "src/external/UserOperation.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

// Based on PayMaster in: https://github.com/eth-infinitism/account-abstraction
contract PayMaster is IPaymaster, Ownable {
    IEntryPoint public entryPoint;

    event UpdateEntryPoint(address indexed _newEntryPoint, address indexed _oldEntryPoint);

    /// @notice Validate that only the entryPoint is able to call a method
    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "SmartWallet: Only entryPoint can call this method");
        _;
    }

    constructor(address _entryPoint) Ownable() {
        entryPoint = IEntryPoint(_entryPoint);
    }

    /// @notice Get the total paymaster stake on the entryPoint
    function getStake() public view returns (uint112) {
        return entryPoint.getDepositInfo(address(this)).stake;
    }

    /// @notice Get the total paymaster deposit on the entryPoint
    function getDeposit() public view returns (uint112) {
        return entryPoint.getDepositInfo(address(this)).deposit;
    }

    //////////////////////// STATE-CHANGING API  /////////////////////////

    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        emit UpdateEntryPoint(_newEntryPoint, address(entryPoint));
        entryPoint = IEntryPoint(_newEntryPoint);
    }

    ////// VALIDATE USER OPERATIONS

    /// @notice Validates that the paymaster will pay for the user transaction. Custom checks can be performed here, to ensure for example
    ///         that the user has sufficient funds to pay for the transaction. It could just return an empty context and deadline to allow
    ///         all transactions by everyone to be paid for through this paymaster.
    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        external
        view
        override
        returns (bytes memory context, uint256 deadline)
    {
        // Pay for all transactions from everyone, with no check
        return ("", 0);
    }

    /// @notice Handler for charging the sender (smart wallet) for the transaction after it has been paid for by the paymaster
    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external onlyEntryPoint {}

    ///// STAKE MANAGEMENT

    /// @notice Add stake for this paymaster to the EntryPoint. Used to allow the paymaster to operate and prevent DDOS
    function addStake(uint32 _unstakeDelaySeconds) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(_unstakeDelaySeconds);
    }

    /// @notice Unlock paymaster stake
    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    /// @notice Withdraw paymaster stake, after having unlocked
    function withdrawStake(address payable to) external onlyOwner {
        entryPoint.withdrawStake(to);
    }

    ///// DEPOSIT MANAGEMENT

    /// @notice Add a deposit for this paymaster to the EntryPoint. Deposit is used to pay user gas fees
    function deposit() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    /// @notice Withdraw paymaster deposit to an address
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        entryPoint.withdrawTo(to, amount);
    }

    /// @notice Withdraw all paymaster deposit to an address
    function withdrawAll(address payable to) external onlyOwner {
        uint112 totalDeposit = getDeposit();
        entryPoint.withdrawTo(to, totalDeposit);
    }
}
