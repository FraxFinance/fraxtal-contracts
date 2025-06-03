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
 * ===================== IFraxStakerEvents =========================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 * @title IFraxStakerEvents
 * @author Frax Finance
 * @notice A collection of events used by the FRAX Staking system.
 */
contract IFraxStakerEvents {
    /**
     * @notice Emitted when a staker initiates withdrawal of the delegatted stake to nodify the delegatee of the action.
     * @param staker The address of the staker
     * @param delegatee The address of the delegatee
     * @param amount The amount of FRAX staked
     * @param withdrawalTimestamp The timestamp at which the withdrawal will be available and the delegation will be revoked
     */
    event DelegationRevocationInitiated(
        address indexed staker,
        address indexed delegatee,
        uint256 amount,
        uint256 withdrawalTimestamp
    );
    /**
     * @notice Emitted when a contributor is added.
     * @param contributor The address of the contributor
     */
    event FraxContributorAdded(address indexed contributor);
    /**
     * @notice Emitted when a contributor is removed.
     * @param contributor The address of the contributor
     */
    event FraxContributorRemoved(address indexed contributor);
    /**
     * @notice Emitted when a sentinel is added.
     * @param sentinel The address of the sentinel
     */
    event FraxSentinelAdded(address indexed sentinel);
    /**
     * @notice Emitted when a sentinel is removed.
     * @param sentinel The address of the sentinel
     */
    event FraxSentinelRemoved(address indexed sentinel);
    /**
     * @notice Emitted when a new admin is proposed.
     * @param currentAdmin The address of the current admin
     * @param proposedFutureAdmin The address of the proposed future admin
     */
    event FutureAdminProposed(address indexed currentAdmin, address indexed proposedFutureAdmin);
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
     * @notice Emitted when a stake is slashed.
     * @param staker The address of the staker
     * @param amount The amount of FRAX slashed
     */
    event Slashed(address indexed staker, uint256 amount);
    /**
     * @notice Emitted when the slashing recipient is updated.
     * @dev The slashing recipient is the address that receives the slashed FRAX.
     * @param oldSlashingRecipient Previous slashing recipient
     * @param newSlashingRecipient Updated slashing recipient
     */
    event SlashingRecipientUpdated(address indexed oldSlashingRecipient, address indexed newSlashingRecipient);
    /**
     * @notice Emitted when the slashing recipient update is proposed.
     * @dev The slashing recipient is the address that receives the slashed FRAX.
     * @param currentSlashingRecipient Current slashing recipient
     * @param proposedSlashingRecipient Proposed new slashing recipient
     */
    event SlashingRecipientUpdateProposed(
        address indexed currentSlashingRecipient,
        address indexed proposedSlashingRecipient
    );
    /**
     * @notice Emitted when a stake is delegated.
     * @param staker Address of the staker
     * @param delegatee Address of the delegatee
     * @param amount Amount of FRAX delegated
     */
    event StakeDelegated(address indexed staker, address indexed delegatee, uint256 amount);
    /**
     * @notice Emitted when a stake delegation is revoked.
     * @dev The amount of FRAX in the event equals the amount of FRAX delegated to this specific delegatee by this
     *  staker.
     * @param staker Address of the staker
     * @param delegatee Address of the delegatee
     * @param amount Amount of FRAX delegation revoked
     */
    event StakeDelegationRevoked(address indexed staker, address indexed delegatee, uint256 amount);
    /**
     * @notice Emitted when a staker is blacklisted.
     * @param staker The address of the blacklisted staker
     * @param amount The amount of FRAX staked
     */
    event StakerBlacklisted(address indexed staker, uint256 amount);
    /**
     * @notice Emitted when a stake is frozen.
     * @param staker The address of the staker
     * @param amount The amount of FRAX staked
     */
    event StakerFrozen(address indexed staker, uint256 amount);
    /**
     * @notice Emitted when a stake is unfrozen.
     * @param staker The address of the staker
     * @param amount The amount of FRAX unfrozen
     */
    event StakerUnfrozen(address indexed staker, uint256 amount);
    /**
     * @notice Emitted when a stake is updated.
     * @param staker The address of the staker
     * @param initialStake The initial amount of FRAX staked
     * @param newStake The new amount of FRAX staked
     */
    event StakeUpdated(address indexed staker, uint256 initialStake, uint256 newStake);
    /**
     * @notice Emitted when a stake withdrawal is cancelled.
     * @param staker The address of the staker
     * @param stake The amount of FRAX staked
     */
    event StakeWithdrawalCancelled(address indexed staker, uint256 stake);
    /**
     * @notice Emitted when a stake withdrawal is initiated.
     * @param staker The address of the staker
     * @param stake The amount of FRAX staked
     * @param withdrawalTimestamp The timestamp at which the withdrawal will be available
     */
    event StakeWithdrawalInitiated(address indexed staker, uint256 stake, uint256 withdrawalTimestamp);
    /**
     * @notice Emitted when the withdrawal cooldown period is updated.
     * @param oldCooldown Previous withdrawal cooldown period
     * @param newCooldown New withdrawal cooldown period
     */
    event WithdrawalCooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
}
