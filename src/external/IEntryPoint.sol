// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";
import "./IStakeManager.sol";
import {IAggregator} from "./IAggregator.sol";

interface IEntryPoint is IStakeManager {
    /**
     *
     * An event emitted after each successful request
     * @param userOpHash - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request
     * @param actualGasCost - the total cost (in gas) of this request.
     * @param actualGasPrice - the actual gas price the sender agreed to pay.
     * @param success - true if the sender transaction succeeded, false if reverted.
     */
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        uint256 actualGasCost,
        uint256 actualGasPrice,
        bool success
    );

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param userOpHash the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(
        bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason
    );

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param paymaster - if paymaster.validatePaymasterUserOp fails, this will be the paymaster's address. if validateUserOp failed,
     *       this value will be zero (since it failed before accessing the paymaster)
     *  @param reason - revert reason
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of account/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, address paymaster, string reason);

    /**
     * error case when a signature aggregator fails to verify the aggregated signature it had created.
     */
    error SignatureValidationFailed(address aggregator);

    //UserOps handled, per aggregator
    struct UserOpsPerAggregator {
        UserOperation[] userOps;
        // aggregator address
        IAggregator aggregator;
        // aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperation.
     * no signature aggregator is used.
     * if any account requires an aggregator (that is, it returned an "actualAggregator" when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
     * @param beneficiary the address to receive the fees
     */
    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
        external;

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     */
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev this method always revert. Successful result is SimulationResult error. other errors are failures.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.
     * @param userOp the user operation to validate.
     */
    function simulateValidation(UserOperation calldata userOp) external;

    /**
     * Successful result from simulateValidation.
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param deadline until what time this userOp is valid (the minimum value of account and paymaster's deadline)
     * @param paymasterInfo stake information about the paymaster (if any)
     */
    error SimulationResult(uint256 preOpGas, uint256 prefund, uint256 deadline, PaymasterInfo paymasterInfo);

    /**
     * returned paymaster info.
     * If the UserOperation contains a paymaster, these fields are filled with the paymaster's stake value and delay.
     * A bundler must verify these values are above the minimal required values, or else reject the UserOperation.
     */
    struct PaymasterInfo {
        uint256 paymasterStake;
        uint256 paymasterUnstakeDelay;
    }

    /**
     * Successful result from simulateValidation, if the account returns a signature aggregator
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param deadline until what time this userOp is valid (the minimum value of account and paymaster's deadline)
     * @param paymasterInfo stake information about the paymaster (if any)
     * @param aggregationInfo signature aggregation info (if the account requires signature aggregator)
     *      bundler MUST use it to verify the signature, or reject the UserOperation
     */
    error SimulationResultWithAggregation(
        uint256 preOpGas,
        uint256 prefund,
        uint256 deadline,
        PaymasterInfo paymasterInfo,
        AggregationInfo aggregationInfo
    );

    /**
     * returned aggregated signature info.
     * the aggregator returned by the account, and its current stake.
     */
    struct AggregationInfo {
        address actualAggregator;
        uint256 aggregatorStake;
        uint256 aggregatorUnstakeDelay;
    }

    /**
     * Get counterfactual sender address.
     *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * this method always revert, and returns the address in SenderAddressResult error
     * @param initCode the constructor code to be passed into the UserOperation.
     */
    // function getSenderAddress(bytes memory initCode) external;

    /**
     * return value of getSenderAddress
     */
    error SenderAddressResult(address sender);
}
