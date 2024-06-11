// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";

contract Fuzz_Test_VestedFXSUtils is BaseTestVeFXS {
    function setUp() public {
        defaultSetup();
    }

    function testFuzz_getDetailedUserLockInfo(uint128 numberOfLocks, address user) public {
        vm.assume(numberOfLocks > 0);
        numberOfLocks = (numberOfLocks % 8) + 1;
        vm.assume(user != address(0));

        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 timeIncrement = (uint128(MAXTIME) - uint128(WEEK * 2)) / numberOfLocks;
        LockedBalance[] memory locks = new LockedBalance[](numberOfLocks);

        for (uint128 i; i < numberOfLocks;) {
            token.mint(user, 1000e18 * (i + 1));
            hoax(user);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(user);
            vestedFXS.createLock(user, 1000e18 * (i + 1), unlockTimestamp);
            locks[i] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: ((unlockTimestamp / uint128(WEEK)) * uint128(WEEK)) });
            unlockTimestamp += timeIncrement;

            unchecked {
                ++i;
            }
        }
        DetailedUserLockInfo memory userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(user);
        LockedBalanceExtended[] memory allLocks = userLockInfo.allLocks;
        assertEq(allLocks.length, locks.length);

        for (uint128 i; i < numberOfLocks;) {
            assertEq(allLocks[i].amount, locks[i].amount);
            assertEq(allLocks[i].end, locks[i].end);

            unchecked {
                ++i;
            }
        }

        skip(3 * timeIncrement);

        userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(user);
        allLocks = userLockInfo.allLocks;
        assertEq(allLocks.length, locks.length);

        for (uint128 i; i < numberOfLocks;) {
            assertEq(allLocks[i].amount, locks[i].amount);
            assertEq(allLocks[i].end, locks[i].end);

            unchecked {
                ++i;
            }
        }

        if (numberOfLocks > 1) {
            hoax(user);
            vestedFXS.withdraw(1);

            userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(user);
            allLocks = userLockInfo.allLocks;
            assertEq(allLocks.length, locks.length - 1);

            locks[1] = locks[locks.length - 1];
            for (uint128 i; i < numberOfLocks - 1;) {
                assertEq(allLocks[i].amount, locks[i].amount);
                assertEq(allLocks[i].end, locks[i].end);

                unchecked {
                    ++i;
                }
            }
        }
    }

    function testFuzz_GetLongestLock(uint128 numberOfLocks, address user, uint128[] memory durations) public {
        vm.assume(numberOfLocks > 0);
        numberOfLocks = (numberOfLocks % 8) + 1;
        vm.assume(user != address(0));
        vm.assume(durations.length > 0);

        uint128 initialTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 unlockTimestamp;
        uint128 longestLockIndex;
        LockedBalance memory longestLock;

        for (uint128 i; i < numberOfLocks;) {
            unlockTimestamp = initialTimestamp + truncateDuration(durations[i % durations.length], uint128(MAXTIME) - uint128(WEEK));
            token.mint(user, 1000e18 * (i + 1));
            hoax(user);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(user);
            vestedFXS.createLock(user, 1000e18 * (i + 1), unlockTimestamp);
            uint128 roundedTimestamp = (unlockTimestamp / uint128(WEEK)) * uint128(WEEK);
            if (roundedTimestamp > longestLock.end) {
                longestLockIndex = i;
                longestLock = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: roundedTimestamp });
            }

            unchecked {
                ++i;
            }
        }

        (LockedBalance memory retrievedLongestLock, uint128 retrievedLongestLockIndex) = vestedFXSUtils.getLongestLock(user);
        assertEq(retrievedLongestLock.amount, longestLock.amount);
        assertEq(retrievedLongestLock.end, longestLock.end);
        assertEq(retrievedLongestLockIndex, longestLockIndex);
    }

    function testFuzz_GetAllActiveLocksOf(uint128 numberOfLocks, address user, uint128[] memory durations) public {
        vm.assume(numberOfLocks > 0);
        numberOfLocks = (numberOfLocks % 8) + 1;
        vm.assume(user != address(0));
        vm.assume(durations.length > 0);

        uint128 initialTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 cutoffTimestamp = initialTimestamp + uint128(MAXTIME / 2);
        uint128 unlockTimestamp;
        uint128 numOfActiveLocks;
        LockedBalance[] memory activeLocks = new LockedBalance[](numberOfLocks);

        for (uint128 i; i < numberOfLocks;) {
            unlockTimestamp = initialTimestamp + truncateDuration(durations[i % durations.length], uint128(MAXTIME) - uint128(WEEK));
            token.mint(user, 1000e18 * (i + 1));
            hoax(user);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(user);
            vestedFXS.createLock(user, 1000e18 * (i + 1), unlockTimestamp);
            uint128 roundedTimestamp = (unlockTimestamp / uint128(WEEK)) * uint128(WEEK);

            if (roundedTimestamp > cutoffTimestamp) {
                activeLocks[numOfActiveLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: roundedTimestamp });
                ++numOfActiveLocks;
            }

            unchecked {
                ++i;
            }
        }

        activeLocks = removeEmptyLocks(activeLocks, numOfActiveLocks);

        skip(cutoffTimestamp - block.timestamp);

        DetailedUserLockInfo memory userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(user);
        LockedBalanceExtended[] memory allActiveLocks = userLockInfo.activeLocks;
        assertEq(allActiveLocks.length, activeLocks.length);

        for (uint128 i; i < numOfActiveLocks;) {
            assertEq(allActiveLocks[i].amount, activeLocks[i].amount);
            assertEq(allActiveLocks[i].end, activeLocks[i].end);

            unchecked {
                ++i;
            }
        }
    }

    function testFuzz_GetAllExpiredLocksOf(uint128 numberOfLocks, address user, uint128[] memory durations) public {
        vm.assume(numberOfLocks > 0);
        numberOfLocks = (numberOfLocks % 8) + 1;
        vm.assume(user != address(0));
        vm.assume(durations.length > 0);

        uint128 initialTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 cutoffTimestamp = initialTimestamp + uint128(MAXTIME / 2);
        uint128 unlockTimestamp;
        uint128 numOfExpiredLocks;
        LockedBalance[] memory expiredLocks = new LockedBalance[](numberOfLocks);

        for (uint128 i; i < numberOfLocks;) {
            unlockTimestamp = initialTimestamp + truncateDuration(durations[i % durations.length], uint128(MAXTIME) - uint128(WEEK));
            token.mint(user, 1000e18 * (i + 1));
            hoax(user);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(user);
            vestedFXS.createLock(user, 1000e18 * (i + 1), unlockTimestamp);
            uint128 roundedTimestamp = (unlockTimestamp / uint128(WEEK)) * uint128(WEEK);

            if (roundedTimestamp <= cutoffTimestamp) {
                expiredLocks[numOfExpiredLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: roundedTimestamp });
                ++numOfExpiredLocks;
            }

            unchecked {
                ++i;
            }
        }

        expiredLocks = removeEmptyLocks(expiredLocks, numOfExpiredLocks);

        skip(cutoffTimestamp - block.timestamp);

        DetailedUserLockInfo memory userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(user);
        LockedBalanceExtended[] memory allExpiredLocks = userLockInfo.expiredLocks;
        assertEq(allExpiredLocks.length, expiredLocks.length);

        for (uint128 i; i < numOfExpiredLocks;) {
            assertEq(allExpiredLocks[i].amount, expiredLocks[i].amount);
            assertEq(allExpiredLocks[i].end, expiredLocks[i].end);

            unchecked {
                ++i;
            }
        }
    }

    function truncateDuration(uint128 duration, uint128 maxDuration) internal pure returns (uint128) {
        uint128 truncatedDuration = ((duration % maxDuration) + (duration / maxDuration) * uint128(WEEK)) % maxDuration;

        truncatedDuration = truncatedDuration == 0 ? uint128(WEEK) : truncatedDuration;

        return truncatedDuration;
    }

    function removeEmptyLocks(LockedBalance[] memory locks, uint128 numberOfLocksToPreserve) internal pure returns (LockedBalance[] memory) {
        LockedBalance[] memory sanitizedLocks = new LockedBalance[](numberOfLocksToPreserve);

        for (uint128 i; i < numberOfLocksToPreserve;) {
            sanitizedLocks[i] = locks[i];

            unchecked {
                ++i;
            }
        }

        return sanitizedLocks;
    }
}
