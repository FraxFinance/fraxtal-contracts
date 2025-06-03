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
// ==================== IFrax Staker Errors ========================
// ====================================================================

/**
 * @title IFraxStakerErrors
 * @author Frax Finance
 * @notice A collection of errors used by the FraxCAP system.
 */
interface IFraxStakerErrors {
    /// Emitted when the staker is already blacklisted.
    error AlreadyBlacklistedStaker();

    /// Emitted when attempting to telegate to someone when you already have an active delegation.
    error AlreadyDelegatedToAnotherDelegatee();

    /// Emitted when the owner tries to add a Frax contributor that is already a Frax contributor.
    error AlreadyFraxContributor();

    /// Emitted when the owner tries to add a Frax sentinel that is already a Frax sentinel.
    error AlreadyFraxSentinel();

    /// Emitted when the staker is aleady frozen.
    error AlreadyFrozenStaker();

    /// Emitted when the contract is already initialized.
    error AlreadyInitialized();

    /// Emitted when the address is already the slashing recipient.
    error AlreadySlashingRecipient();

    /// Emitted when the staker is blacklisted.
    error BlacklistedStaker();

    /// Emitted when attempting to delegete to self.
    error CannotDelegateToSelf();

    /// Emitted when a user tries to transfer their stake.
    error CannotTransferStake();

    /// Emitted when the contract is operational and the action that requires it to be paused is attempted.
    error ContractOperational();

    /// Emitted when the contract is paused and the action that requires it to be operational is attempted.
    error ContractPaused();

    /// Emitted when the staker is frozen and can't perform any actions.
    error FrozenStaker();

    /// Emitted when attempting to create a stake with a zero amount.
    error InvalidStakeAmount();

    /// Emitted when the staker tries to delegate their stake when they already have an active non-delegated stake.
    error NonDelegatedStakeAlreadyExists();

    /// Emitted when there is no proposed slashing recipient.
    error NoProposedSlashingRecipient();

    /// Emitted when the owner tries to remove a Frax contributor that is not a Frax contributor.
    error NotFraxContributor();

    /// Emitted when the owner tries to remove a Frax sentinel that is not a Frax sentinel.
    error NotFraxSentinel();

    /// Emitted when the staker is not frozen.
    error NotFrozenStaker();

    /// Emitted when attempting to update the slashing recipient before the update time delay has passed.
    error SlashingRecipientUpdateNotAvailableYet();

    /// Emitted when attempting to add a delegatee that would overflow the maximum number of delegatees.
    /// The maximum number of delegatees is 255. This is to prevent OOG reverts when iterating over the delegatees.
    error TooManyDelegations();

    /// Emitted when the FRAX transfer fails.
    error TransferFailed();

    /// Emitted when revoking all delegations for a single staker fails.
    error UnableToRevokeAllDelegations();

    /// Emitted when a user tries to deposit FRAX while they aleady have a stake with initiated withdrawal.
    /// They need to either cancel the withdrawal or wait for it to finish.
    error WithdrawalInitiated();

    /// Emitted when a user tries to withdraw their stake but it is not available to bo withdrawn yet.
    error WithdrawalNotAvailable();

    /// Emitted when a user tries to withdraw their stake but it has not been initiated yet.
    error WithdrawalNotInitiated();
}
