// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ============================ IFloxEvents ===========================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 * @title IFloxEvents
 * @author Frax Finance
 * @notice A collection of events used by the Flox Incentives system
 */
contract IFloxEvents {
    /**
     * @notice Emitted when a contributor is added.
     * @param contributor The address of the contributor
     */
    event ContributorAdded(address indexed contributor);
    /**
     * @notice Emitted when a contributor is removed.
     * @param contributor The address of the contributor
     */
    event ContributorRemoved(address indexed contributor);
    /**
     * @notice Emitted when a new admin is proposed.
     * @param currentAdmin The address of the current admin
     * @param proposedFutureAdmin The address of the proposed future admin
     */
    event FutureAdminProposed(address indexed currentAdmin, address indexed proposedFutureAdmin);
    /**
     * @notice Emitted when incentives are allocated to a recipient.
     * @param recipient The address of the recipient
     * @param amount The amount of FXS allocated
     * @param lockIndex The lock index of the recipient
     */
    event IncentiveAllocated(address indexed recipient, uint256 amount, uint128 lockIndex);
    /**
     * @notice Emitted when the stats for an epoch are updated.
     * @param epoch The epoch
     * @param startBlock The start block of the epoch
     * @param endBlock The end block of the epoch
     * @param totalIncentvesDistributed The total amount of FXS distributed in the epoch
     * @param totalRecipients The total number of recipients in the epoch
     * @param incentivesAllocationStructProof The Keccak256 hash of the full incentives allocation struct
     */
    event IncentiveStatsUpdate(
        uint256 epoch,
        uint128 startBlock,
        uint128 endBlock,
        uint256 totalIncentvesDistributed,
        uint256 totalRecipients,
        bytes32 incentivesAllocationStructProof
    );
    /**
     * @notice Emitted when a new admin is set.
     * @param oldAdmin The address of the old admin
     * @param newAdmin The address of the new admin
     */
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);
    /**
     * @notice Emitted when the new lock duration is updated.
     * @param newLockDuration The new lock duration
     */
    event NewLockDurationUpdated(uint128 newLockDuration);
}
