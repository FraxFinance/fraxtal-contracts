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
 * ===================== IFloxConverterEvents =========================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 * @title IFloxConverterEvents
 * @author Frax Finance
 * @notice A collection of events used by the FloxCAP system.
 */
contract IFloxConverterEvents {
    /**
     * @notice Emitted when the user receives their FRAX distribution.
     * @param user The address of the user receiving the distribution
     * @param amount Amount of FRAX distributed to the user
     */
    event DistributionAllocated(address indexed user, uint256 amount);
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
     * @notice Emitted when a redeemal epoch is finalized.
     * @param epochId ID of the finalized redeemal epoch
     */
    event RedeemalEpochFinalized(uint256 epochId);
    /**
     * @notice Emitted when a new epoch is initiated.
     * @param epochId The ID of the epoch
     * @param firstBlock The block number of the first block of the epoch
     * @param lastBlock The block number of the last block of the epoch
     * @param totalFraxDistributed The total amount of FRAX distributed in the epoch
     */
    event RedeemalEpochInitiated(uint256 epochId, uint64 firstBlock, uint64 lastBlock, uint256 totalFraxDistributed);
    /**
     * @notice Emitted when the redeemal epoch data has been populated and is ready for distribution.
     * @param epochId ID of the redeemal epoch
     * @param firstEpochBlock First block number of the redeemal epoch
     * @param lastEpochBlock Last block number of the redeemal epoch
     * @param totalFloxStakeUnits Amount of total Flox stake units submitted in the redeemal epoch
     */
    event RedeemalEpochPopulated(
        uint256 epochId,
        uint256 firstEpochBlock,
        uint256 lastEpochBlock,
        uint256 totalFloxStakeUnits
    );
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
     * @notice Emmited when the user's redeemal epoch data is updated.
     * @param epochId ID of the redeemal epoch
     * @param user Address of the user having their data updated
     * @param fxtlPointsRedeemed Amount of FXTL points redeemed in the redeemal epoch
     * @param floxStakeUnits Amount of Flox stake units by the user in the redeemal epoch
     */
    event UserEpochDataUpdated(
        uint256 indexed epochId,
        address indexed user,
        uint256 fxtlPointsRedeemed,
        uint256 floxStakeUnits
    );
    /**
     * @notice Emitted when user stats are updated.
     * @param user Address of the user having their stats updated
     * @param previousAmountOfFxtlPointsRedeemed Amount of FXTL points redeemed before the update
     * @param newAmountOfFxtlPointsRedeemed Amount of FXTL points redeemed after the update
     */
    event UserStatsUpdated(
        address indexed user,
        uint256 previousAmountOfFxtlPointsRedeemed,
        uint256 newAmountOfFxtlPointsRedeemed
    );
    /**
     * @notice Emitted when the yearly FRAX distribution is updated.
     * @param oldYearlyFraxDistribution The previous yearly FRAX distribution
     * @param newYearlyFraxDistribution The new yearly FRAX distribution
     */
    event YearlyFraxDistributionUpdated(uint256 oldYearlyFraxDistribution, uint256 newYearlyFraxDistribution);
}
