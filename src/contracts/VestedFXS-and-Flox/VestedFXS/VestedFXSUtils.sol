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
 * ========================== VestedFXSUtils ==========================
 * ====================================================================
 * Helper and utility functions for VestedFXS
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 *
 * Voting escrow to have time-weighted votes
 * Votes have a weight depending on time, so that users are committed
 * to the future of (whatever they are voting for).
 * The weight in this implementation is linear, and lock cannot be more than maxtime:
 * w ^
 * 1 +        /
 *   |      /
 *   |    /
 *   |  /
 *   |/
 * 0 +--------+------> time
 *       maxtime (4 years?)
 */
import { IVestedFXS } from "src/contracts/VestedFXS-and-Flox/interfaces/IVestedFXS.sol";
import { IveFXSStructs } from "src/contracts/VestedFXS-and-Flox/VestedFXS/IveFXSStructs.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "forge-std/console2.sol";

/**
 * @title VestedFXSUtils
 * @author Frax Finance
 * @notice This utility smart contract provides functions to get extended information from the VestedFXS contract.
 */
contract VestedFXSUtils is IveFXSStructs {
    IVestedFXS public immutable veFXS;
    IERC20Metadata public immutable token;

    /**
     * @notice Contract constructor
     * @param _vestedFXS Address of the VestedFXS contract
     */
    constructor(address _vestedFXS) {
        veFXS = IVestedFXS(_vestedFXS);
        token = IERC20Metadata(veFXS.token());
    }

    /**
     * @notice Used to get all of the locks of a given user.
     * @dev The locks are retrieved indiscriminately, regardless of whether they are active or expired.
     * @param _user Address of the user
     * @return _userLockInfo DetailedUserLockInfo for the user. Includes _allLocks, _activeLocks, _expiredLocks, and FXS totals for these respectively
     * @dev This lives on Fraxtal and will mostly be read-called in UIs, so gas not really an issue here
     */
    function getDetailedUserLockInfo(address _user) public view returns (DetailedUserLockInfo memory _userLockInfo) {
        // Get the total number of locks
        uint256 _totalLocks = veFXS.numLocks(_user);
        uint128 _numberOfActiveLocks;

        // Set the number locks for the user
        _userLockInfo.numberOfLocks = _totalLocks;

        // Set the user
        _userLockInfo.user = _user;

        // Initialize _allLocks
        _userLockInfo.allLocks = new LockedBalanceExtended[](_totalLocks);

        // Initial _isActive, which tracks if a given index is active
        bool[] memory _isActive = new bool[](_totalLocks);

        // Loop through all of the locks
        for (uint256 i; i < _userLockInfo.allLocks.length; ) {
            // Update the _allLocks return data
            LockedBalance memory _thisLock = veFXS.lockedByIndex(_user, uint128(i));
            _userLockInfo.allLocks[i].id = veFXS.indicesToIds(_user, uint128(i));
            _userLockInfo.allLocks[i].index = uint128(i);
            _userLockInfo.allLocks[i].amount = _thisLock.amount;
            _userLockInfo.allLocks[i].end = _thisLock.end;
            _userLockInfo.totalFxs[0] += _thisLock.amount;

            // Determine whether it is active or expired
            if (_thisLock.end > block.timestamp) {
                // Update isActive tracking
                _isActive[i] = true;

                // Update _totalFxs for active locks
                _userLockInfo.totalFxs[1] += _thisLock.amount;

                unchecked {
                    ++_numberOfActiveLocks;
                }
            } else {
                // Update _totalFxs for expired locks
                _userLockInfo.totalFxs[2] += _thisLock.amount;
            }
            unchecked {
                ++i;
            }
        }

        // Initialize _activeLocks and _expiredLocks
        _userLockInfo.activeLocks = new LockedBalanceExtended[](_numberOfActiveLocks);
        _userLockInfo.expiredLocks = new LockedBalanceExtended[](_totalLocks - _numberOfActiveLocks);

        // Loop through all of the locks again, this time for assigning to _activeLocks and _expiredLocks
        uint128 _activeCounter;
        uint128 _expiredCounter;
        for (uint256 i; i < _userLockInfo.allLocks.length; ) {
            // Get the lock info
            LockedBalanceExtended memory _thisLock = _userLockInfo.allLocks[i];

            // Sort the lock as either active or expired
            if (_isActive[i]) {
                // Active
                _userLockInfo.activeLocks[_activeCounter] = _thisLock;

                unchecked {
                    ++_activeCounter;
                }
            } else {
                // Expired
                _userLockInfo.expiredLocks[_expiredCounter] = _thisLock;

                unchecked {
                    ++_expiredCounter;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to get all of the locks of the given users. Same underlying code as getDetailedUserLockInfo
     * @dev The locks are retrieved indiscriminately, regardless of whether they are active or expired.
     * @param _users Addresses of the users
     * @return _userLockInfos DetailedUserLockInfo[] for the users. Includes _allLocks, _activeLocks, _expiredLocks, and FXS totals for these respectively
     * @dev This lives on Fraxtal and will mostly be read-called in UIs, so gas not really an issue here
     */
    function getDetailedUserLockInfoBulk(
        address[] memory _users
    ) public view returns (DetailedUserLockInfo[] memory _userLockInfos) {
        // Save the number of user addresses
        uint256 _numUsers = _users.length;

        // Initialize the return array
        _userLockInfos = new DetailedUserLockInfo[](_numUsers);

        // Loop through all of the users and get their detailed lock info
        for (uint256 i = 0; i < _numUsers; ) {
            _userLockInfos[i] = getDetailedUserLockInfo(_users[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Used to get the longest lock of a given user.
     * @dev The longest lock is the lock with the timestamp furthest in the future (can also be in the past if there are no active locks).
     * @param user Address of the user
     * @return The longest lock of the user
     * @return The index of the longest lock
     */
    function getLongestLock(address user) public view returns (LockedBalance memory, uint128) {
        LockedBalance[] memory locks = new LockedBalance[](veFXS.numLocks(user));
        LockedBalance memory longestLock;
        uint128 longestLockIndex;

        for (uint256 i = 0; i < locks.length; ) {
            uint128 currentEnd = veFXS.lockedByIndex(user, uint128(i)).end;
            if (currentEnd > longestLock.end) {
                longestLock.end = currentEnd;
                longestLock.amount = veFXS.lockedByIndex(user, uint128(i)).amount;
                longestLockIndex = uint128(i);
            }

            unchecked {
                i++;
            }
        }

        return (longestLock, longestLockIndex);
    }

    /**
     * @notice Used to get longest locks of muliple users.
     * @dev This returns the longest lock indiscriminately, regardless of whether it is active or expired.
     * @dev The return value is an array of LongestLock structs, which contain the lock, the index of the lock, and the user.
     * @param users Array of addresses of the users
     * @return The LongestLocks of the users
     */
    function getLongestLockBulk(address[] memory users) public view returns (LongestLock[] memory) {
        LongestLock[] memory longestLocks = new LongestLock[](users.length);
        LockedBalance memory longestLock;
        uint128 longestLockIndex;

        for (uint256 i = 0; i < users.length; ) {
            for (uint256 j; j < veFXS.numLocks(users[i]); ) {
                uint128 currentEnd = veFXS.lockedByIndex(users[i], uint128(j)).end;
                if (currentEnd > longestLock.end) {
                    longestLock.end = currentEnd;
                    longestLock.amount = veFXS.lockedByIndex(users[i], uint128(j)).amount;
                    longestLockIndex = uint128(j);
                }

                unchecked {
                    ++j;
                }
            }

            longestLocks[i] = LongestLock({ lock: longestLock, lockIndex: longestLockIndex, user: users[i] });

            delete longestLock;
            delete longestLockIndex;

            unchecked {
                ++i;
            }
        }

        return longestLocks;
    }

    /**
     * @notice Calculate the APPROXIMATE amount of veFXS, given an FXS amount and a lock length. Cruder version of balanceOf math. Useful for sanity checks.
     * @param _fxsAmount The amount of FXS
     * @param _lockSecsU128 The length of the lock
     * @return _expectedVeFXS The expected amount of veFXS. May be slightly off from actual (~1%)
     * @dev Useful to compare to the slope/bias-based balancedOf to make sure the math is working
     */
    function getCrudeExpectedVeFXSOneLock(
        int128 _fxsAmount,
        uint128 _lockSecsU128
    ) public view returns (uint256 _expectedVeFXS) {
        // veFXS = FXS in emergency unlock situation
        if (veFXS.emergencyUnlockActive()) return uint256(int256(_fxsAmount));

        // Truncate _timeLeft down to the nearest week
        int128 _lockSecsI128 = int128((_lockSecsU128 / veFXS.WEEK_UINT128()) * veFXS.WEEK_UINT128());

        // Calculate the expected veFXS
        _expectedVeFXS = uint256(uint128(_fxsAmount + ((3 * _fxsAmount * _lockSecsI128) / veFXS.MAXTIME_INT128())));
    }

    /**
     * @notice Calculate the APPROXIMATE amount of veFXS, given FXS amounts and lock lengths. Cruder version of balanceOf math. Useful for sanity checks.
     * @param _fxsAmounts The amounts of FXS
     * @param _lockSecsU128 The length of the locks
     * @return _expectedVeFXS The expected amount of veFXS (summed). May be slightly off from actual (~1%)
     * @dev Useful to compare to the slope/bias-based balancedOf to make sure the math is working
     */
    function getCrudeExpectedVeFXSMultiLock(
        int128[] memory _fxsAmounts,
        uint128[] memory _lockSecsU128
    ) public view returns (uint256 _expectedVeFXS) {
        // See if you are in an emergency unlock situation
        bool _isEmergencyUnlockActive = veFXS.emergencyUnlockActive();

        // Loop through the locks
        for (uint128 i = 0; i < _fxsAmounts.length; ++i) {
            // veFXS = FXS in emergency unlock situation
            if (_isEmergencyUnlockActive) _expectedVeFXS += uint256(int256(_fxsAmounts[i]));
            else _expectedVeFXS += getCrudeExpectedVeFXSOneLock(_fxsAmounts[i], _lockSecsU128[i]);
        }
    }

    /**
     * @notice Calculate the APPROXIMATE amount of veFXS a specific user should have. Cruder version of balanceOf math. Useful for sanity checks.
     * @param _user The address of the user
     * @return _expectedVeFXS The expected amount of veFXS (summed). May be slightly off from actual (~1%)
     * @dev Useful to compare to the slope/bias-based balancedOf to make sure the math is working
     */
    function getCrudeExpectedVeFXSUser(address _user) public view returns (uint256 _expectedVeFXS) {
        // Get all of the user's locks
        DetailedUserLockInfo memory _userLockInfo = getDetailedUserLockInfo(_user);

        // See if you are in an emergency unlock situation
        bool _isEmergencyUnlockActive = veFXS.emergencyUnlockActive();

        // Loop through all of the user's locks
        for (uint128 i = 0; i < _userLockInfo.numberOfLocks; ) {
            // Get the lock info
            LockedBalanceExtended memory _lockInfo = _userLockInfo.allLocks[i];

            // For the emergency unlock situation, veFXS = FXS
            if (_isEmergencyUnlockActive) {
                _expectedVeFXS += uint256(int256(_lockInfo.amount));
            } else {
                // Get the lock time to use
                uint128 _lockSecsToUse;
                if (_lockInfo.end < uint128(block.timestamp)) {
                    _lockSecsToUse = 0;
                } else {
                    _lockSecsToUse = _lockInfo.end - uint128(block.timestamp);
                }

                // Get the approximate veFXS
                _expectedVeFXS += getCrudeExpectedVeFXSOneLock(_lockInfo.amount, _lockSecsToUse);
            }

            unchecked {
                ++i;
            }
        }
    }
}
