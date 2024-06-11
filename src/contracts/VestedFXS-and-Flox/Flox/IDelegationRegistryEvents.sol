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
// ==================== IDelegationRegistryEvents =====================
// ====================================================================

/**
 * @title IDelegationRegistryEvents
 * @author Frax Finance
 * @notice A collection of events used by the Flox DelegationRegistry
 */
contract IDelegationRegistryEvents {
    /**
     * @notice Emitted when a delegator updates their delegation settings.
     * @param delegator Address delegating their points
     * @param previousDelegatee Address that the delegator delegated to before
     * @param newDelegatee Address that the delegator is delegating to now
     */
    event DelegationUpdated(address indexed delegator, address indexed previousDelegatee, address indexed newDelegatee);
    /**
     * @notice Emitted when a new address is added as a Frax Contributor.
     * @param contributor The address added as the contributor
     */
    event FraxContributorAdded(address indexed contributor);
    /**
     * @notice Emitted when an address is removed as a Frax Contributor.
     * @param contributor The address removed as the contributor
     */
    event FraxContributorRemoved(address indexed contributor);
}
