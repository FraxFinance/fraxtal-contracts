// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import "forge-std/console2.sol";

contract Unit_Test_VestedFXSUtils is BaseTestVeFXS {
    uint64 public constant MAXTIME_UINT64 = 4 * 365 * 86_400; // 4 years
    // _expectedVeFXS = uint256(uint128(_fxsAmount + ((3 * _fxsAmount *_timeLeft_i128) / MAXTIME)));
    uint64 public LOCK_SECONDS_2X_U64; // Number of weeks to get a 2x veFXS multiplier
    uint64 public LOCK_SECONDS_3X_U64; // Number of weeks to get a 3x veFXS multiplier
    uint64 public LOCK_SECONDS_4X_U64; // Number of weeks to get a 4x veFXS multiplier

    function setUp() public {
        super.defaultSetup();

        // Set some variables
        LOCK_SECONDS_2X_U64 = (1 * MAXTIME_UINT64) / 3;
        LOCK_SECONDS_3X_U64 = (2 * MAXTIME_UINT64) / 3;
        LOCK_SECONDS_4X_U64 = MAXTIME_UINT64;
    }

    function test_GetAllLocksOf() public {
        uint128 numOfLocks = 8;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        LockedBalance[] memory locks = new LockedBalance[](numOfLocks);

        for (uint128 i; i < numOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);
            locks[i] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        DetailedUserLockInfo memory bobLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);
        LockedBalanceExtended[] memory allLocks = bobLockInfo.allLocks;
        assertEq(allLocks.length, locks.length);

        for (uint128 i; i < numOfLocks;) {
            assertEq(allLocks[i].amount, locks[i].amount);
            assertEq(allLocks[i].end, locks[i].end);

            unchecked {
                ++i;
            }
        }

        skip(3 * uint128(WEEK));
        bobLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);
        allLocks = bobLockInfo.allLocks;
        assertEq(allLocks.length, locks.length);

        for (uint128 i; i < numOfLocks;) {
            assertEq(allLocks[i].amount, locks[i].amount);
            assertEq(allLocks[i].end, locks[i].end);

            unchecked {
                ++i;
            }
        }

        hoax(bob);
        vestedFXS.withdraw(1);

        bobLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);
        allLocks = bobLockInfo.allLocks;
        assertEq(allLocks.length, locks.length - 1);

        locks[1] = locks[locks.length - 1];

        for (uint128 i; i < numOfLocks - 1;) {
            assertEq(allLocks[i].amount, locks[i].amount);
            assertEq(allLocks[i].end, locks[i].end);

            unchecked {
                ++i;
            }
        }
    }

    function test_GetAllActiveLocksOf() public {
        uint128 numOfLocks = 8;
        uint128 numOfActiveLocks;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 cutoffTimestamp = unlockTimestamp + uint128(WEEK * 5) + uint128(WEEK / 2);
        LockedBalance[] memory locks = new LockedBalance[](numOfLocks);

        for (uint128 i; i < numOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);
            if (unlockTimestamp > cutoffTimestamp) {
                locks[numOfActiveLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                ++numOfActiveLocks;
            }
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        locks = removeEmptyLocks(locks, numOfActiveLocks);

        skip(cutoffTimestamp - block.timestamp);

        DetailedUserLockInfo memory bobLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);
        LockedBalanceExtended[] memory activeLocks = bobLockInfo.activeLocks;
        assertEq(activeLocks.length, locks.length);

        for (uint128 i; i < locks.length;) {
            assertEq(activeLocks[i].amount, locks[i].amount);
            assertEq(activeLocks[i].end, locks[i].end);

            unchecked {
                ++i;
            }
        }
    }

    function test_GetAllExpiredLocksOf() public {
        uint128 numOfLocks = 8;
        uint128 numOfExpiredLocks;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 cutoffTimestamp = unlockTimestamp + uint128(WEEK * 5) + uint128(WEEK / 2);
        LockedBalance[] memory locks = new LockedBalance[](numOfLocks);

        for (uint128 i; i < numOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);
            if (unlockTimestamp < cutoffTimestamp) {
                locks[numOfExpiredLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                ++numOfExpiredLocks;
            }
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        locks = removeEmptyLocks(locks, numOfExpiredLocks);

        skip(cutoffTimestamp - block.timestamp);
        DetailedUserLockInfo memory bobLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);
        LockedBalanceExtended[] memory expiredLocks = bobLockInfo.expiredLocks;
        assertEq(expiredLocks.length, locks.length);

        for (uint128 i; i < locks.length;) {
            assertEq(expiredLocks[i].amount, locks[i].amount);
            assertEq(expiredLocks[i].end, locks[i].end);

            unchecked {
                ++i;
            }
        }
    }

    function test_GetLongestLock() public {
        uint128 numOfLocks = 8;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 longestLockIndex;
        LockedBalance memory lock;

        for (uint128 i; i < numOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);

            if (i == numOfLocks - 1) {
                lock = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                longestLockIndex = i;
            }

            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        (VestedFXSUtils.LockedBalance memory longestLock, uint128 retrievedLongestLockIndex) = vestedFXSUtils.getLongestLock(bob);

        assertEq(retrievedLongestLockIndex, longestLockIndex);
        assertEq(longestLock.amount, lock.amount);
        assertEq(longestLock.end, lock.end);
    }

    function test_BulkGetAllLocksOf() public {
        address[] memory addresses = new address[](2);
        addresses[0] = address(bob);
        addresses[1] = address(alice);
        uint128 firstNumOfLocks = 8;
        uint128 secondNumOfLocks = 5;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        LockedBalance[] memory firstLocks = new LockedBalance[](firstNumOfLocks);
        LockedBalance[] memory secondLocks = new LockedBalance[](secondNumOfLocks);

        for (uint128 i; i < firstNumOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);
            firstLocks[i] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        for (uint128 i; i < secondNumOfLocks;) {
            token.mint(alice, 1000e18 * (i + 1));
            hoax(alice);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(alice);
            vestedFXS.createLock(alice, 1000e18 * (i + 1), unlockTimestamp);
            secondLocks[i] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        DetailedUserLockInfo[] memory bulkLockInfos = vestedFXSUtils.getDetailedUserLockInfoBulk(addresses);

        assertEq(bulkLockInfos.length, addresses.length);

        assertEq(bulkLockInfos[0].user, addresses[0]);
        assertEq(bulkLockInfos[1].user, addresses[1]);

        assertEq(bulkLockInfos[0].numberOfLocks, firstNumOfLocks);
        assertEq(bulkLockInfos[1].numberOfLocks, secondNumOfLocks);

        LockedBalanceExtended[] memory retrievedFirstLocks = bulkLockInfos[0].allLocks;
        LockedBalanceExtended[] memory retrievedSecondLocks = bulkLockInfos[1].allLocks;

        assertEq(retrievedFirstLocks.length, firstLocks.length);
        assertEq(retrievedSecondLocks.length, secondLocks.length);

        for (uint128 i; i < firstLocks.length;) {
            assertEq(retrievedFirstLocks[i].amount, firstLocks[i].amount);
            assertEq(retrievedFirstLocks[i].end, firstLocks[i].end);

            unchecked {
                ++i;
            }
        }

        for (uint128 i; i < secondLocks.length;) {
            assertEq(retrievedSecondLocks[i].amount, secondLocks[i].amount);
            assertEq(retrievedSecondLocks[i].end, secondLocks[i].end);

            unchecked {
                ++i;
            }
        }
    }

    function test_GetLongestLockBulk() public {
        address[] memory addresses = new address[](2);
        addresses[0] = address(bob);
        addresses[1] = address(alice);
        uint128 firstNumOfLocks = 8;
        uint128 secondNumOfLocks = 5;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        LockedBalance memory firstLock;
        LockedBalance memory secondLock;

        for (uint128 i; i < firstNumOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);

            if (i == firstNumOfLocks - 1) {
                firstLock = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            }

            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        for (uint128 i; i < secondNumOfLocks;) {
            token.mint(alice, 1000e18 * (i + 1));
            hoax(alice);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(alice);
            vestedFXS.createLock(alice, 1000e18 * (i + 1), unlockTimestamp);

            if (i == secondNumOfLocks - 1) {
                secondLock = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            }

            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        VestedFXSUtils.LongestLock[] memory longestLocks = vestedFXSUtils.getLongestLockBulk(addresses);

        assertEq(longestLocks.length, addresses.length);

        assertEq(longestLocks[0].user, addresses[0]);
        assertEq(longestLocks[1].user, addresses[1]);

        assertEq(longestLocks[0].lockIndex, firstNumOfLocks - 1);
        assertEq(longestLocks[1].lockIndex, secondNumOfLocks - 1);

        assertEq(longestLocks[0].lock.amount, firstLock.amount);
        assertEq(longestLocks[0].lock.end, firstLock.end);

        assertEq(longestLocks[1].lock.amount, secondLock.amount);
        assertEq(longestLocks[1].lock.end, secondLock.end);
    }

    function test_BulkGetAllActiveLocksOf() public {
        address[] memory addresses = new address[](2);
        addresses[0] = address(bob);
        addresses[1] = address(alice);
        uint128 firstNumOfLocks = 8;
        uint128 secondNumOfLocks = 5;
        uint128 numOfFirstActiveLocks;
        uint128 numOfSecondActiveLocks;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 cutoffTimestamp = unlockTimestamp + uint128(WEEK * 5) + uint128(WEEK / 2);
        LockedBalance[] memory firstLocks = new LockedBalance[](firstNumOfLocks);
        LockedBalance[] memory secondLocks = new LockedBalance[](secondNumOfLocks);

        for (uint128 i; i < firstNumOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);
            if (unlockTimestamp > cutoffTimestamp) {
                firstLocks[numOfFirstActiveLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                ++numOfFirstActiveLocks;
            }
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        unlockTimestamp -= uint128(WEEK * 7);

        for (uint128 i; i < secondNumOfLocks;) {
            token.mint(alice, 1000e18 * (i + 1));
            hoax(alice);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(alice);
            vestedFXS.createLock(alice, 1000e18 * (i + 1), unlockTimestamp);
            if (unlockTimestamp > cutoffTimestamp) {
                secondLocks[numOfSecondActiveLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                ++numOfSecondActiveLocks;
            }
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        firstLocks = removeEmptyLocks(firstLocks, numOfFirstActiveLocks);
        secondLocks = removeEmptyLocks(secondLocks, numOfSecondActiveLocks);

        skip(cutoffTimestamp - block.timestamp);

        VestedFXSUtils.DetailedUserLockInfo[] memory bulkLockInfos = vestedFXSUtils.getDetailedUserLockInfoBulk(addresses);

        assertEq(bulkLockInfos.length, addresses.length, "bulkLockInfos.length != addresses.length");

        assertEq(bulkLockInfos[0].user, addresses[0], "bulkLockInfos[0].user != addresses[0]");
        assertEq(bulkLockInfos[1].user, addresses[1], "bulkLockInfos[1].user != addresses[1]");

        assertEq(bulkLockInfos[0].activeLocks.length, numOfFirstActiveLocks, "bulkLockInfos[0].activeLocks.length != numOfFirstActiveLocks");
        assertEq(bulkLockInfos[1].activeLocks.length, numOfSecondActiveLocks, "bulkLockInfos[1].activeLocks.length != numOfSecondActiveLocks");

        for (uint128 i; i < numOfFirstActiveLocks;) {
            assertEq(bulkLockInfos[0].activeLocks[i].amount, firstLocks[i].amount, "bulkLockInfos[0].activeLocks[i].amount != firstLocks[i].amount");
            assertEq(bulkLockInfos[0].activeLocks[i].end, firstLocks[i].end, "bulkLockInfos[0].activeLocks[i].end != firstLocks[i].end");

            unchecked {
                ++i;
            }
        }

        for (uint128 i; i < numOfSecondActiveLocks;) {
            assertEq(bulkLockInfos[1].activeLocks[i].amount, secondLocks[i].amount, "bulkLockInfos[1].activeLocks[i].amount != secondLocks[i].amount");
            assertEq(bulkLockInfos[1].activeLocks[i].end, secondLocks[i].end, "bulkLockInfos[1].activeLocks[i].end != secondLocks[i].end");

            unchecked {
                ++i;
            }
        }
    }

    function test_BulkGetAllExpiredLocksOf() public {
        address[] memory addresses = new address[](2);
        addresses[0] = address(bob);
        addresses[1] = address(alice);
        uint128 firstNumOfLocks = 7;
        uint128 secondNumOfLocks = 5;
        uint128 numOfFirstExpiredLocks;
        uint128 numOfSecondExpiredLocks;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 cutoffTimestamp = unlockTimestamp + uint128(WEEK * 5) + uint128(WEEK / 2);
        LockedBalance[] memory firstLocks = new LockedBalance[](firstNumOfLocks);
        LockedBalance[] memory secondLocks = new LockedBalance[](secondNumOfLocks);

        for (uint128 i; i < firstNumOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(bob);
            vestedFXS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);
            if (unlockTimestamp < cutoffTimestamp) {
                firstLocks[numOfFirstExpiredLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                ++numOfFirstExpiredLocks;
            }
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        unlockTimestamp -= uint128(WEEK * 5);

        for (uint128 i; i < secondNumOfLocks;) {
            token.mint(alice, 1000e18 * (i + 1));
            hoax(alice);
            token.approve(address(vestedFXS), 1000e18 * (i + 1));
            hoax(alice);
            vestedFXS.createLock(alice, 1000e18 * (i + 1), unlockTimestamp);
            if (unlockTimestamp < cutoffTimestamp) {
                secondLocks[numOfSecondExpiredLocks] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                ++numOfSecondExpiredLocks;
            }
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        firstLocks = removeEmptyLocks(firstLocks, numOfFirstExpiredLocks);
        secondLocks = removeEmptyLocks(secondLocks, numOfSecondExpiredLocks);

        skip(cutoffTimestamp - block.timestamp);

        VestedFXSUtils.DetailedUserLockInfo[] memory bulkLockInfos = vestedFXSUtils.getDetailedUserLockInfoBulk(addresses);

        assertEq(bulkLockInfos.length, addresses.length);

        assertEq(bulkLockInfos[0].user, addresses[0]);
        assertEq(bulkLockInfos[1].user, addresses[1]);

        assertEq(bulkLockInfos[0].expiredLocks.length, numOfFirstExpiredLocks);
        assertEq(bulkLockInfos[1].expiredLocks.length, numOfSecondExpiredLocks);

        for (uint128 i; i < numOfFirstExpiredLocks;) {
            assertEq(bulkLockInfos[0].expiredLocks[i].amount, firstLocks[i].amount);
            assertEq(bulkLockInfos[0].expiredLocks[i].end, firstLocks[i].end);

            unchecked {
                ++i;
            }
        }

        for (uint128 i; i < numOfSecondExpiredLocks;) {
            assertEq(bulkLockInfos[1].expiredLocks[i].amount, secondLocks[i].amount);
            assertEq(bulkLockInfos[1].expiredLocks[i].end, secondLocks[i].end);

            unchecked {
                ++i;
            }
        }
    }

    function test_getCrudeExpectedVeFXSMultiLock() public {
        // Get two crude veFXSs one at a time
        uint256 _expectedVeFXSOneLockNum1 = vestedFXSUtils.getCrudeExpectedVeFXSOneLock(1e18, uint128(WEEK));
        uint256 _expectedVeFXSOneLockNum2 = vestedFXSUtils.getCrudeExpectedVeFXSOneLock(10e18, uint128(LOCK_SECONDS_2X_U64));

        // Get two crude veFXSs in one call
        int128[] memory _fxsAmounts = new int128[](2);
        _fxsAmounts[0] = 1e18;
        _fxsAmounts[1] = 10e18;
        uint128[] memory _lockSecsU128 = new uint128[](2);
        _lockSecsU128[0] = uint128(WEEK);
        _lockSecsU128[1] = uint128(LOCK_SECONDS_2X_U64);
        uint256 _expectedVeFXSMultiLock = vestedFXSUtils.getCrudeExpectedVeFXSMultiLock(_fxsAmounts, _lockSecsU128);

        // The sums of both methods should match, and it should be about 21 veFXS
        assertEq(_expectedVeFXSOneLockNum1 + _expectedVeFXSOneLockNum2, _expectedVeFXSMultiLock, "Sums of getCrudeExpectedVeFXS methods should match");
        assertApproxEqRel(_expectedVeFXSOneLockNum1 + _expectedVeFXSOneLockNum2, 21e18, ONE_PCT_DELTA, "Sum of getCrudeExpectedVeFXSOneLock should be 21 veFXS");
        assertApproxEqRel(_expectedVeFXSMultiLock, 21e18, ONE_PCT_DELTA, "Sum of getCrudeExpectedVeFXSMultiLock should be 21 veFXS");
    }

    function test_BalanceOf() public {
        token.mint(bob, 100e18);

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 40e18, unlockTimestamp);
        hoax(bob);
        vestedFXS.createLock(bob, 10e18, unlockTimestamp);

        uint256 initialVotingPower = vestedFXS.balanceOfAllLocksAtTime(bob, block.timestamp);
        uint256 halfwayVotingPower = vestedFXS.balanceOfAllLocksAtTime(bob, block.timestamp + uint128(MAXTIME) / 2);
        uint256 finalVotingPower = vestedFXS.balanceOfAllLocksAtTime(bob, unlockTimestamp);

        assertGt(initialVotingPower, halfwayVotingPower);
        assertGt(halfwayVotingPower, finalVotingPower);
    }

    function test_BalanceOfAt() public {
        token.mint(bob, 100e18);

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 10e18, unlockTimestamp);
        hoax(bob);
        vestedFXS.createLock(bob, 20e18, unlockTimestamp);

        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block0 = block.number;
        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block1 = block.number;
        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block2 = block.number;

        uint256 initialVotingPower = vestedFXS.balanceOfAt(bob, block0);
        uint256 halfwayVotingPower = vestedFXS.balanceOfAllLocksAtBlock(bob, block1);
        uint256 finalVotingPower = vestedFXS.balanceOfAt(bob, block2);
        uint256 noVotingPower = vestedFXS.balanceOfAllLocksAtBlock(bob, 1);

        assertGt(initialVotingPower, halfwayVotingPower);
        assertGt(halfwayVotingPower, finalVotingPower);
        assertEq(noVotingPower, 0);

        vm.expectRevert(VestedFXS.InvalidBlockNumber.selector);
        vestedFXS.balanceOfAt(bob, block.number + 1);
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

    function test_TotalFXSSupply() public {
        token.mint(bob, 1000e18);
        token.mint(alice, 1000e18);
        hoax(bob);
        token.approve(address(vestedFXS), 1000e18);
        hoax(alice);
        token.approve(address(vestedFXS), 1000e18);

        assertEq(vestedFXS.totalFXSSupply(), 0);

        vestedFXS.checkpoint();

        vm.roll(block.number + 10);
        hoax(bob);
        token.approve(address(vestedFXS), 60e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
        uint256 balance0 = vestedFXS.totalFXSSupply();

        vm.roll(block.number + 10);
        hoax(alice);
        token.approve(address(vestedFXS), 60e18);
        hoax(alice);
        vestedFXS.createLock(alice, 50e18, unlockTimestamp);
        uint256 balance1 = vestedFXS.totalFXSSupply();

        vm.roll(block.number + 10);
        skip(uint256(uint128(MAXTIME)) + 1);
        hoax(bob);
        vestedFXS.withdraw(0);
        uint256 balance2 = vestedFXS.totalFXSSupply();

        assertEq(balance0, 50e18);
        assertEq(balance1, 100e18);
        assertEq(balance2, 50e18);
    }

    function test_TotalFXSSupplyAt() public {
        token.mint(bob, 1000e18);
        token.mint(alice, 1000e18);
        hoax(bob);
        token.approve(address(vestedFXS), 1000e18);
        hoax(alice);
        token.approve(address(vestedFXS), 1000e18);

        assertEq(vestedFXS.totalFXSSupplyAt(block.number), 0);

        vestedFXS.checkpoint();

        vm.roll(block.number + 10);
        hoax(bob);
        token.approve(address(vestedFXS), 60e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
        uint256 block0 = block.number;

        vm.roll(block.number + 10);
        hoax(alice);
        token.approve(address(vestedFXS), 60e18);
        hoax(alice);
        vestedFXS.createLock(alice, 50e18, unlockTimestamp);
        uint256 block1 = block.number;

        vm.roll(block.number + 10);
        skip(uint256(uint128(MAXTIME)) + 1);
        hoax(bob);
        vestedFXS.withdraw(0);
        uint256 block2 = block.number;

        assertEq(vestedFXS.totalFXSSupplyAt(block0), 50e18);
        assertEq(vestedFXS.totalFXSSupplyAt(block1), 100e18);
        assertEq(vestedFXS.totalFXSSupplyAt(block2), 50e18);

        vm.expectRevert(VestedFXS.InvalidBlockNumber.selector);
        vestedFXS.totalFXSSupplyAt(block.number + 1);
    }

    function test_TotalSupplyAt() public {
        token.mint(bob, 1000e18);
        token.mint(alice, 1000e18);
        hoax(bob);
        token.approve(address(vestedFXS), 1000e18);
        hoax(alice);
        token.approve(address(vestedFXS), 1000e18);

        vestedFXS.checkpoint();

        hoax(bob);
        token.approve(address(vestedFXS), 60e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
        hoax(alice);
        token.approve(address(vestedFXS), 60e18);
        hoax(alice);
        vestedFXS.createLock(alice, 50e18, unlockTimestamp);

        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);
        vestedFXS.checkpoint();
        uint256 blockToValidate = block.number;
        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);
        vestedFXS.checkpoint();

        uint256 votingPowerBob = vestedFXS.balanceOfOneLockAtBlock(bob, 0, blockToValidate);
        uint256 votingPowerAlice = vestedFXS.balanceOfOneLockAtBlock(alice, 0, blockToValidate);
        uint256 totalSupply = vestedFXS.totalSupplyAt(blockToValidate);

        assertEq(totalSupply, votingPowerBob + votingPowerAlice);

        vm.expectRevert(VestedFXS.InvalidBlockNumber.selector);
        vestedFXS.totalSupplyAt(block.number + 1);
    }
}
