// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ==================== IFlox Converter Errors ========================
// ====================================================================

/**
 * @title IFloxConverterErrors
 * @author Frax Finance
 * @notice A collection of errors used by the FloxCAP system.
 */
interface IFloxConverterErrors {
    /// Emitted the user already received their FRAX distribution for the current redeemal epoch.
    /// @param user The address of the user that already received their distribution
    error AlreadyDistributed(address user);

    /// Emitted when the owner tries to add a Flox contributor that is already a Flox contributor.
    error AlreadyFloxContributor();

    /// Emitted when the contract is already initialized.
    error AlreadyInitialized();

    /// Emitted when the contract already usin g the veFRAX balances.
    error AlreadyUsingVeFRAX();

    /// Emitted when a user tries to transfer their stake.
    error CannotTransferStake();

    /// Emitted when the contract is operational and the action that requires it to be paused is attempted.
    error ContractOperational();

    /// Emitted when the contract is paused and the action that requires it to be operational is attempted.
    error ContractPaused();

    /// Emitted when the distribution of FRAX fails fo an address.
    /// @param user The address of the user that failed to receive the distribution
    error DistributionFailed(address user);

    /// Emitted when the epoch is already finalized.
    error EpochAlreadyFinalized();

    /// Emitted when the epoch is already populated.
    error EpochAlreadyPopulated();

    /// Emitted when the epoch is not initiated yet.
    error EpochNotInitiated();

    /// Emitted when the epoch is already populated.
    error EpochNotPopulated();

    /// Emitted when the staker tries to stake more FRAX than they have allowed the FloxCAP smart contract to transfer.
    error InsufficientAllowance();

    /// Emitted when attempting to stake more FRAX than own balance.
    error InsufficientFraxBalance();

    /// Emitted when attempting to pass arrays of different lengths.
    error InvalidArrayLength();

    /// Emitted when passing a zero amount of FRAX redeemed for the redeemal epoch.
    error InvalidFraxRedeemedAmount();

    /// Emitted when passing a zero amount of FXTL points redeemed for the redeemal epoch.
    error InvalidFxtlPointsAmount();

    /// Emitted when trying to pass a zero amount as the last block number of the redeemal epoch.
    error InvalidLastBlockNumber();

    /// Emitted when attempting to create a stake with a zero amount.
    error InvalidStakeAmount();

    /// Emitted when attempting to pass a zero amount of Flox stake units when initiating a redeemal epoch.
    error InvalidTotalFloxStakeUnitsAmount();

    /// Emitted when the divisor for veFRAX is invalid.
    error InvalidVeFRAXDivisor();

    /// Emitted when the owner tries to remove a Flox contributor that is not a Flox contributor.
    error NotFloxContributor();

    /// Emitted when the contract is not using veFRAX balances.
    error NotUsingVeFRAX();

    /// Emitted when reentrancy is detected.
    error Reentrancy();

    /// Emitted when attempting to get the data for an uninitiated redeemal epoch.
    error UninitiatedRedeemalEpoch();

    /// Emitted when attempting to update user redeemal epoch data when the user's redeemal epoch data has already been set.
    error UserRedeemalDataAlreadyPresent();

    /// Emitted when a user tries to deposit FRAX while they aleady have a stake with initiated withdrawal.
    /// They need to either cancel the withdrawal or wait for it to finish.
    error WithdrawalInitiated();

    /// Emitted when a user tries to withdraw their stake but it is not available to bo withdrawn yet.
    error WithdrawalNotAvailable();

    /// Emitted when a user tries to withdraw their stake but it has not been initiated yet.
    error WithdrawalNotInitiated();

    /// Emitted when attempting to set the yearly FRAX distribution to zero.
    error ZeroYearlyFraxDistribution();
}
