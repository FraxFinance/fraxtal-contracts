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
// ========================= Non Reentrant ============================
// ====================================================================

/**
 * @title Non Reentrant
 * @author Frax Finance
 * @notice A smart contract that ansures external calls are not exploited by reentrancy.
 */
contract NonReentrant {
    /// A boolean flag to indicate if the contract is currently executing a function.
    bool private executing;

    /// An error that is thrown when a reentrancy attack is detected.
    error ReentrancyDetected();

    /**
     * @notice A modifier that prevents reentrancy by ensuring that the function is not currently executing.
     */
    modifier nonReentrant() {
        if (executing) revert ReentrancyDetected();

        executing = true;
        _;
        executing = false;
    }
}
