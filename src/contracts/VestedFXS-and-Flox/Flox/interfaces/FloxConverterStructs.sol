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
// ==================== IFlox Converter Structs =======================
// ====================================================================

import { IFloxConverterErrors } from "./IFloxConverterErrors.sol";
import { IFloxConverterEvents } from "./IFloxConverterEvents.sol";

/**
 * @title IFloxConverterStructs
 * @author Frax Finance
 * @notice A collection of structs used by the FloxCAP system.
 */
contract FloxConverterStructs is IFloxConverterErrors, IFloxConverterEvents {
    /**
     * @notice A struct used to keep track of the redeemal epochs.
     * @dev The Flox stake units is the sum of all the Flox stake units of the users obtained by the FXTL points of
     *  their users with the FloxCAP boost applied.
     * @param initiated True if the redeemal epoch data has been initialized
     * @param populated True if the user redeemal epoch data has been populated
     * @param finalized True if the redeemal epoch data has been allocated and initialized
     * @param firstBlock The block number of the first block of the redeemal epoch
     * @param lastBlock The block number of the last block of the redeemal epoch
     * @param totalFxtlPointsRedeemed The total amount of FXTL points redeemed in the redeemal epoch
     * @param totalFraxDistributed The total amount of FRAX distributed in the redeemal epoch
     * @param totalFloxStakeUnits The total amount of Flox stake units redeemed in the redeemal epoch
     * @param __gap Reserved 10 storage slots for future upgrades
     */
    struct RedeemalEpoch {
        bool initiated;
        bool populated;
        bool finalized;
        uint64 firstBlock;
        uint64 lastBlock;
        uint256 totalFxtlPointsRedeemed;
        uint256 totalFraxDistributed;
        uint256 totalFloxStakeUnits;
        uint256[10] __gap; // reserve extra storage for future upgrades
    }
    /**
     * @notice A struct used to keep track of the user data in the redeemal epochs.
     * @param fxtlPointsRedeemed The amount of FXTL points redeemed in the epoch
     * @param fraxReceived The amount of FRAX received in the epoch
     * @param floxStakeUnits The amount of Flox stake units redeemed in the epoch
     * @param __gap Reserved 10 storage slots for future upgrades
     */

    struct RedeemalEpochUserData {
        uint256 fxtlPointsRedeemed;
        uint256 fraxReceived;
        uint256 floxStakeUnits;
        uint256[10] __gap; // reserve extra storage for future upgrades
    }
    /**
     * @notice A struct used to keep track of the user data.
     * @param totalFxtlPointsRedeemed The total amount of FXTL points redeemed in all the redeemal epochs
     * @param totalFraxReceived The total amount of FRAX received in all the redeemal epochs
     * @param __gap Reserve 10 storage slots for future upgrades
     */

    struct UserData {
        uint256 totalFxtlPointsRedeemed;
        uint256 totalFraxReceived;
        uint256[10] __gap; // reserve extra storage for future upgrades
    }
}
