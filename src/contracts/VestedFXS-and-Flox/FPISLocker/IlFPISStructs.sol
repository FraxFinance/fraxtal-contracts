// SPDX-License-Identifier: MIT
// @version 0.2.8
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
 * ======================== lFPISStructs ==============================
 * ====================================================================
 * Structs of lFPIS contracts (lFPIS)
 * Frax Finance: https://github.com/FraxFinance
 */
interface IlFPISStructs {
    /// @notice Detailed lock info for a user
    /// @param user Address of the user
    /// @param allLocks All of the locks of the user
    /// @param numberOfLocks The total number of locks that the user has
    /// @param activeLocks Only the active locks of the user
    /// @param expiredLocks Only the expired locks of the user
    /// @param totalFpis The total amount of FPIS that the user has for all, active, and expired locks respectively
    struct DetailedUserLockInfo {
        address user;
        uint256 numberOfLocks;
        LockedBalanceExtended[] allLocks;
        LockedBalanceExtended[] activeLocks;
        LockedBalanceExtended[] expiredLocks;
        int128[3] totalFpis;
    }

    /// @notice Basic information about a lock
    /// @param amount The amount that is locked
    /// @param end The ending timestamp for the lock
    /// @dev We cannot really do block numbers per se b/c slope is per time, not per block and per block could be fairly bad b/c Ethereum changes blocktimes. What we can do is to extrapolate ***At functions
    struct LockedBalance {
        int128 amount;
        uint128 end; // This should more than suffice for our needs and allows the struct to be packed
    }

    /// @notice Extended information about a lock
    /// @param id The ID of the lock
    /// @param index The index of the lock. If index is 0, do not trust it unless isInUse is also true
    /// @param amount The amount that is locked
    /// @param end The ending timestamp for the lock
    struct LockedBalanceExtended {
        uint256 id;
        uint128 index;
        int128 amount;
        uint128 end;
    }

    /// @notice Lock ID Info. Cannot be a simple mapping because lock indeces are in constant flux and index 0 vs null is ambiguous.
    /// @param id The ID of the lock
    /// @param index The index of the lock. If index is 0, do not trust it unless isInUse is also true
    /// @param isInUse If the lock ID is currently in use
    struct LockIdIdxInfo {
        uint256 id;
        uint128 index;
        bool isInUse;
    }

    /// @notice Point in a user's lock
    /// @param bias The bias of the point
    /// @param slope The slope of the point
    /// @param ts The timestamp of the point
    /// @param blk The block of the point
    /// @param fpisAmt The amount of FPIS at the point
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 fpisAmt;
    }

    /// @notice Longest lock info for a user
    /// @param lock The longest lock of the user
    /// @param lockIndex The index of the longest lock
    /// @param user The address of the user
    struct LongestLock {
        LockedBalance lock;
        uint128 lockIndex;
        address user;
    }
}
