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
// ======================== IFxtlPointsEvents =========================
// ====================================================================

/**
 * @title IFxtlPointsEvents
 * @author Frax Finance
 * @notice A collection of events used by the Flox FxtlPoints
 */
contract IFxtlPointsEvents {
    /**
     * @notice Emitted when a new address is added as a Fxtl Contributor.
     * @param contributor The address added as the contributor
     */
    event FxtlContributorAdded(address indexed contributor);

    /**
     * @notice Emitted when an address is removed as a Fxtl Contributor.
     * @param contributor The address removed as the contributor
     */
    event FxtlContributorRemoved(address indexed contributor);
}
