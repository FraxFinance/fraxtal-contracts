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
// ======================= IFrax Staker Structs =======================
// ====================================================================

import { IFraxStakerErrors } from "./IFraxStakerErrors.sol";
import { IFraxStakerEvents } from "./IFraxStakerEvents.sol";

/**
 * @title IFraxStakerStructs
 * @author Frax Finance
 * @notice A collection of structs used by the Frax Staking system.
 */
contract FraxStakerStructs is IFraxStakerErrors, IFraxStakerEvents {
    /**
     * @notice A struct used to represent the stake of a user.
     * @dev The `unlockTime` is set to 0 if the stake is not slated for withdrawal.
     * @param amountStaked The amount of FRAX staked
     * @param amountDelegated The amount of FRAX delegated to other stakers
     * @param amountDelegatedToStaker The amount of FRAX delegated to this staker
     * @param unlockTime The time at which the stake can be withdrawn
     * @param delegatee The delegatee address of the staker
     * @param initiatedWithdrawal True if the stake withdrawal has been initiated
     * @param __gap Reserved 10 storage slots for future upgrades
     */
    struct Stake {
        uint256 amountStaked;
        uint256 amountDelegated;
        uint256 amountDelegatedToStaker;
        uint256 unlockTime;
        address delegatee;
        bool initiatedWithdrawal;
        uint256[10] __gap; // reserve extra storage for future upgrades
    }
}
