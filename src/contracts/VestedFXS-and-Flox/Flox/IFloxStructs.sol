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
 * =========================== IFloxStructs ===========================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 * @title FloxStructs
 * @author Frax Finance
 * @notice A collection of structs used by the Flox Incentives system
 */
contract IFloxStructs {
    struct IncentivesStats {
        uint128 startBlock;
        uint128 endBlock;
        uint256 totalIncentvesDistributed;
        uint256 totalRecipients;
        bytes32 incentivesAllocationStructProof;
    }

    struct IncentivesInput {
        address recipient;
        uint8 lockIndex;
        uint88 amount;
    }
}
