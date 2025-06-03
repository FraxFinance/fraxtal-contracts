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
// ==================== IFlox Capacitor Errors ========================
// ====================================================================

/**
 * @title IFloxCapacitorErrors
 * @author Frax Finance
 * @notice A collection of errors used by the FloxCAP system.
 */
interface IFloxCapacitorErrors {
    /// Emitted when attempting to delegate to someone when you already have an active delegation.
    error AlreadyDelegated();

    /// Emitted when the owner tries to add a Flox contributor that is already a Flox contributor.
    error AlreadyFloxContributor();

    /// Emitted when the contract is already initialized.
    error AlreadyInitialized();

    /// Emitted when the contract already usin g the veFRAX balances.
    error AlreadyUsingVeFRAX();

    /// Emitted when the array lengths don't match.
    error ArrayLengthMismatch();

    /// Emitted when the delegator is blacklisted by the delegatee.
    error BlacklistedDelegator();

    /// Emitted when attempting to delegate to self.
    error CannotDelegateToSelf();

    /// Emitted when the contract is operational and the action that requires it to be paused is attempted.
    error ContractOperational();

    /// Emitted when the contract is paused and the action that requires it to be operational is attempted.
    error ContractPaused();

    /// Emitted when attempting to reject delegatee that is not your own.
    error DelegationMismatch();

    /// Emitted when attempting to delegate with balance below the delegation threshold.
    error InsufficientBalanceForDelegation();

    /// Emitted when the divisor for veFRAX is invalid.
    error InvalidVeFRAXDivisor();

    /// Emitted when there are no active delegations.
    error NoActiveDelegations();

    /// Emitted when the specified delegator is not blacklisted for the user.
    error NotBlacklistedDelegator();

    /// Emitted when the owner tries to remove a Flox contributor that is not a Flox contributor.
    error NotFloxContributor();

    /// Emitted when the contract is not using veFRAX balances.
    error NotUsingVeFRAX();

    /// Emitted when the delegatee already has the maximum number of incoming delegations.
    error TooManyIncomingDelegations();
}
