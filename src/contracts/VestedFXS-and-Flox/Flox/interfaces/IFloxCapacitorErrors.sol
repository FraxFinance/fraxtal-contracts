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

    /// Emitted when the owner tries to add a Flox contributor that is already an existing Flox contributor.
    error AlreadyFloxContributor();

    /// Emitted when the contract is already initialized.
    error AlreadyInitialized();

    /// Emitted when the contract is already using the veFRAX Aggregator balances.
    error AlreadyUsingVeFRAX();

    /// Emitted when the array lengths don't match.
    error ArrayLengthMismatch();

    /// Emitted when attempting to delegate to self.
    error CannotDelegateToSelf();

    /// Emitted when the divisor for veFRAX is invalid.
    error InvalidVeFRAXDivisor();

    /// Emitted when there are no active delegations.
    error NoActiveDelegations();

    /// Emitted when the specified delegator is not blacklisted for the user.
    error NotBlacklistedDelegator();

    /// Emitted when either 1) The sender is not a flox contributor or 2) the owner tries to remove a Flox contributor that is not an existing Flox contributor.
    error NotFloxContributor();

    /// Emitted when the caller is not the owner or a Flox contributor.
    error NotOwnerOrFloxContributor();

    /// Emitted when the contract is not using veFRAX balances.
    error NotUsingVeFRAX();

    /// Emitted when the address passed is the zero address.
    error ZeroAddress();
}
