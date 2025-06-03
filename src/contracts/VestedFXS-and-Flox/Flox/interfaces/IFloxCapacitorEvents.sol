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
 * ===================== IFloxCapacitorEvents =========================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 * @title IFloxCapacitorEvents
 * @author Frax Finance
 * @notice A collection of events used by the FloxCAP system.
 */
contract IFloxCapacitorEvents {
    /**
     * @notice Emitted when a user blacklists a delegator or removes them from the blacklist.
     * @param user Address of the user that doesn't want to accept delegations from delegator
     * @param delegator Address of the delegator being added or removed from the user's blacklist
     * @param isBlacklisted Boolean value signifying whether the user is being added or removed from the blacklist
     */
    event BlacklistDelegationStatusUpdated(address indexed user, address indexed delegator, bool isBlacklisted);
    /**
     * @notice Emitted when a new delegation is added.
     * @param user The address of the user delegating their balance
     * @param delegatee The address of the user receiving the delegation
     */
    event DelegationAdded(address indexed user, address indexed delegatee);
    /**
     * @notice Emitted when a delegation is removed.
     * @param user The address of the user delegating their balance
     * @param delegatee The address of the user whose delegation is being removed
     */
    event DelegationRemoved(address indexed user, address indexed delegatee);
    /**
     * @notice Emitted when a contributor is added.
     * @param contributor The address of the contributor
     */
    event FloxContributorAdded(address indexed contributor);
    /**
     * @notice Emitted when a contributor is removed.
     * @param contributor The address of the contributor
     */
    event FloxContributorRemoved(address indexed contributor);
    /**
     * @notice Emitted when a new admin is proposed.
     * @param currentAdmin The address of the current admin
     * @param proposedFutureAdmin The address of the proposed future admin
     */
    event FutureAdminProposed(address indexed currentAdmin, address indexed proposedFutureAdmin);
    /**
     * @notice Emitted when the minimum delegation balance is updated.
     * @param oldMinimum The previous minimum delegation balance
     * @param newMinimum The new minimum delegation balance
     */
    event MinimumDelegationBalanceUpdated(uint256 oldMinimum, uint256 newMinimum);
    /**
     * @notice Emitted when a new admin is set.
     * @param oldAdmin The address of the old admin
     * @param newAdmin The address of the new admin
     */
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);
    /**
     * @notice Emitted when the contract is paused or unpaused.
     * @param paused True if the contract is paused, false if it is unpaused
     * @param timestamp The timestamp at which the pause or unpause occurred
     */
    event OperationPaused(bool paused, uint256 timestamp);
    /**
     * @notice Emitted when the incoming delegation limit is updated.
     * @param oldLimit Previous limit for incoming delegation
     * @param newLimit New limit for incoming delegation
     */
    event IncomingDelegationLimitUpdated(uint16 oldLimit, uint16 newLimit);
    /**
     * @notice Emitted when the veFRAX divisor is updated.
     * @param oldVeFRAXDivisor Previous divisor for veFRAX
     * @param newVeFRAXDivisor New divisor for veFRAX
     */
    event VeFRAXDivisorUpdated(uint256 oldVeFRAXDivisor, uint256 newVeFRAXDivisor);
    /**
     * @notice Emitted when the veFRAX use is enabled.
     */
    event VeFraxUseEnabled();
    /**
     * @notice Emitted when the veFRAX use is disabled.
     */
    event VeFraxUseDisabled();
}
