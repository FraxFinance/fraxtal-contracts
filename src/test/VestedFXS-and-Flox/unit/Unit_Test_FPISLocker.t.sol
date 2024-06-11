// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestLFPIS } from "../BaseTestLFPIS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FPISLocker, IlFPISStructs } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLocker.sol";
import { FPISLockerUtils } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLockerUtils.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_FPISLocker is BaseTestLFPIS {
    FPISLockerUtils fpisLockerUtils;

    function lockedFPISSetup() public {
        console.log("lockedFPISSetup() called");
        super.defaultSetup();

        // Mint FPIS to the test users
        token.mint(alice, 100e18);
        token.mint(bob, 100e18);

        // Set the FPISLockerUtils
        fpisLockerUtils = new FPISLockerUtils(address(lockedFPIS));
    }

    function test_commitTransferOwnership() public {
        lockedFPISSetup();

        vm.expectEmit(false, false, false, true);
        emit CommitOwnership(bob);
        lockedFPIS.commitTransferOwnership(bob);
        assertEq(lockedFPIS.futureLockerAdmin(), bob);

        vm.expectRevert(FPISLocker.LockerAdminOnly.selector);
        hoax(bob);
        lockedFPIS.commitTransferOwnership(bob);
    }

    function test_acceptTransferOwnership() public {
        lockedFPISSetup();

        lockedFPIS.commitTransferOwnership(bob);
        vm.expectEmit(false, false, false, true);
        emit ApplyOwnership(bob);
        hoax(bob);
        lockedFPIS.acceptTransferOwnership();
        assertEq(lockedFPIS.lockerAdmin(), bob);

        vm.expectRevert(FPISLocker.FutureLockerAdminOnly.selector);
        hoax(alice);
        lockedFPIS.acceptTransferOwnership();

        // Since the future admin needs to accept the transfer, it is extremely unlikely this happens, but just in case..
        hoax(bob);
        lockedFPIS.commitTransferOwnership(address(0));
        hoax(address(0));
        vm.expectRevert(FPISLocker.LockerAdminNotSet.selector);
        lockedFPIS.acceptTransferOwnership();
    }

    function test_toggleContractPause() public {
        lockedFPISSetup();

        assertFalse(lockedFPIS.isPaused());

        vm.expectEmit(false, false, false, true);
        emit ContractPause(true);
        lockedFPIS.toggleContractPause();

        assertTrue(lockedFPIS.isPaused());

        vm.expectEmit(false, false, false, true);
        emit ContractPause(false);
        lockedFPIS.toggleContractPause();

        vm.expectRevert(FPISLocker.LockerAdminOnly.selector);
        hoax(bob);
        lockedFPIS.toggleContractPause();
    }

    function test_activateEmergencyUnlock() public {
        lockedFPISSetup();

        assertEq(lockedFPIS.emergencyUnlockActive(), false);

        lockedFPIS.activateEmergencyUnlock();
        assertEq(lockedFPIS.emergencyUnlockActive(), true);

        vm.expectRevert(FPISLocker.LockerAdminOnly.selector);
        hoax(bob);
        lockedFPIS.activateEmergencyUnlock();
    }

    function test_setFloxContributor() public {
        lockedFPISSetup();

        assertEq(lockedFPIS.floxContributors(bob), false);

        vm.expectEmit(true, true, false, true);
        emit FloxContributorUpdate(bob, true);
        lockedFPIS.setFloxContributor(bob, true);
        assertEq(lockedFPIS.floxContributors(bob), true);

        vm.expectEmit(true, true, false, true);
        emit FloxContributorUpdate(bob, false);
        lockedFPIS.setFloxContributor(bob, false);
        assertEq(lockedFPIS.floxContributors(bob), false);

        vm.expectRevert(FPISLocker.LockerAdminOnly.selector);
        hoax(bob);
        lockedFPIS.setFloxContributor(bob, true);
    }

    function test_recoverIERC20() public {
        lockedFPISSetup();

        MintableBurnableTestERC20 unrelated = new MintableBurnableTestERC20("unrelated", "UNR");
        unrelated.mint(address(lockedFPIS), 100e18);

        assertEq(unrelated.balanceOf(address(lockedFPIS)), 100e18);
        lockedFPIS.recoverIERC20(address(unrelated), 100e18);
        assertEq(unrelated.balanceOf(address(lockedFPIS)), 0);

        vm.expectRevert(FPISLocker.LockerAdminOnly.selector);
        hoax(bob);
        lockedFPIS.recoverIERC20(address(unrelated), 100e18);

        vm.expectRevert(FPISLocker.UnableToRecoverFPIS.selector);
        lockedFPIS.recoverIERC20(address(token), 100e18);
    }

    function test_getLastUserSlope() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 5 * 10 ** 19);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 5 * 10 ** 19, unlockTimestamp);

        int128 slope = lockedFPIS.getLastUserSlope(bob, 0);
        int128 expectedSlope = (int128(5 * 10 ** 19) * VOTE_WEIGHT_MULTIPLIER) / MAXTIME / VOTE_BASIS_POINTS;

        assertEq(slope, expectedSlope);
    }

    function test_userPointHistoryTs() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 5 * 10 ** 19);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 5 * 10 ** 19, unlockTimestamp);

        assertEq(block.timestamp, lockedFPIS.userPointHistoryTs(bob, 0, 1));
    }

    function test_lockedEnd() public {
        lockedFPISSetup();

        assertEq(lockedFPIS.lockedEnd(bob, 0), 0);

        hoax(bob);
        token.approve(address(lockedFPIS), 5 * 10 ** 19);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 5 * 10 ** 19, unlockTimestamp);

        assertEq(unlockTimestamp, lockedFPIS.lockedEnd(bob, 0));
    }

    function test_createLock() public {
        lockedFPISSetup();

        assertEq(token.balanceOf(address(lockedFPIS)), 0);
        LockedBalance memory lBalance;
        lBalance.amount = 0;
        lBalance.end = 0;
        LockedBalance memory retrievedBalance;
        uint256 lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        uint8 numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        uint8 numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 0);

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        vm.expectEmit(true, true, true, true, address(lockedFPIS));
        emit Deposit(bob, bob, unlockTimestamp, 50e18, CREATE_LOCK_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(0, 50e18);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(lockedFPIS)), 50e18);
        assertEq(token.balanceOf(bob), 50e18);
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 1);
        assertEq(numOfFloxContributorLocks, 0);
        assertFalse(lockedFPIS.isLockCreatedByFloxContributor(bob, lockId));

        lockedFPIS.setFloxContributor(bob, true);
        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        vm.expectEmit(true, true, true, true, address(lockedFPIS));
        emit Deposit(alice, bob, unlockTimestamp, 50e18, CREATE_LOCK_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(50e18, 100e18);
        hoax(bob);
        lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(lockedFPIS)), 100e18);
        assertEq(token.balanceOf(bob), 0);
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        lockId = lockedFPIS.indicesToIds(alice, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.lockedById(alice, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 1);
        assertTrue(lockedFPIS.isLockCreatedByFloxContributor(alice, lockId));

        lockedFPIS.setFloxContributor(bob, false);
        vm.expectRevert(FPISLocker.NotLockingForSelfOrFloxContributor.selector);
        hoax(bob);
        lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

        vm.expectRevert(FPISLocker.MinLockAmount.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 0, unlockTimestamp);

        vm.expectRevert(FPISLocker.MustBeInAFutureEpochWeek.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, uint128(block.timestamp - 1));

        vm.expectRevert(FPISLocker.LockCanOnlyBeUpToFourYears.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, uint128(block.timestamp) + uint128(MAXTIME) * 2);

        token.mint(alice, 10 ** 21);
        hoax(alice);
        token.approve(address(lockedFPIS), 10 ** 21);
        uint128 currentLocks = lockedFPIS.numberOfUserCreatedLocks(alice);
        uint8 maximumUserLocks = 8;
        for (uint128 i = currentLocks; i < maximumUserLocks / 2;) {
            hoax(alice);
            lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 4);
        assertEq(numOfFloxContributorLocks, 1);

        lockedFPIS.setFloxContributor(bob, true);
        token.mint(bob, 10 ** 21);
        hoax(bob);
        token.approve(address(lockedFPIS), 10 ** 21);
        currentLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(alice);
        uint8 maximumContributorLocks = 8;
        for (uint128 i = currentLocks; i < maximumContributorLocks / 2;) {
            hoax(bob);
            lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 4);
        assertEq(numOfFloxContributorLocks, 4);

        currentLocks = lockedFPIS.numberOfUserCreatedLocks(alice);
        for (uint128 i = currentLocks; i < maximumUserLocks;) {
            hoax(alice);
            lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 8);
        assertEq(numOfFloxContributorLocks, 4);

        currentLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(alice);
        for (uint128 i = currentLocks; i < maximumContributorLocks;) {
            hoax(bob);
            lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 8);
        assertEq(numOfFloxContributorLocks, 8);

        vm.expectRevert(FPISLocker.MaximumUserLocksReached.selector);
        hoax(alice);
        lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

        vm.expectRevert(FPISLocker.MaximumFloxContributorLocksReached.selector);
        hoax(bob);
        lockedFPIS.createLock(alice, 50e18, unlockTimestamp);

        currentLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        for (uint128 i = currentLocks; i < maximumUserLocks;) {
            hoax(bob);
            lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        uint8 finalNumOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 8);
        assertEq(numOfFloxContributorLocks, finalNumOfFloxContributorLocks);

        vm.expectRevert(FPISLocker.MaximumUserLocksReached.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        lockedFPIS.setFloxContributor(alice, true);
        hoax(alice);
        token.approve(address(lockedFPIS), 50e18);
        hoax(alice);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfFloxContributorLocks, finalNumOfFloxContributorLocks + 1);

        lockedFPIS.toggleContractPause();
        vm.expectRevert(FPISLocker.OperationIsPaused.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_depositFor() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(lockedFPIS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        hoax(alice);
        token.approve(address(lockedFPIS), 20e18);
        vm.expectEmit(true, true, true, true, address(lockedFPIS));
        emit Deposit(bob, alice, unlockTimestamp, 20e18, DEPOSIT_FOR_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(50e18, 70e18);
        hoax(alice);
        lockedFPIS.depositFor(bob, 20e18, 0);

        assertEq(token.balanceOf(address(lockedFPIS)), 70e18);
        assertEq(token.balanceOf(alice), 80e18);
        assertEq(token.balanceOf(bob), 50e18);
        lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, lockId);
        lBalance.amount = 70e18;
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        vm.expectRevert(FPISLocker.MinLockAmount.selector);
        lockedFPIS.depositFor(bob, 0, 0);

        vm.expectRevert(FPISLocker.NoExistingLockFound.selector);
        lockedFPIS.depositFor(alice, 20e18, 0);

        vm.expectRevert(FPISLocker.LockExpired.selector);
        skip(uint128(MAXTIME * 2));
        lockedFPIS.depositFor(bob, 20e18, 0);

        lockedFPIS.toggleContractPause();
        vm.expectRevert(FPISLocker.OperationIsPaused.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_increaseAmount() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 70e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(lockedFPIS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        vm.expectEmit(true, true, true, true, address(lockedFPIS));
        emit Deposit(bob, bob, unlockTimestamp, 20e18, INCREASE_LOCK_AMOUNT, block.timestamp);
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(50e18, 70e18);
        hoax(bob);
        lockedFPIS.increaseAmount(20e18, 0);

        assertEq(token.balanceOf(address(lockedFPIS)), 70e18);
        assertEq(token.balanceOf(bob), 30e18);
        lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, lockId);
        lBalance.amount = 70e18;
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        vm.expectRevert(FPISLocker.MinLockAmount.selector);
        lockedFPIS.increaseAmount(0, 0);

        hoax(alice);
        vm.expectRevert(FPISLocker.NoExistingLockFound.selector);
        lockedFPIS.increaseAmount(20e18, 0);

        hoax(bob);
        vm.expectRevert(FPISLocker.LockExpired.selector);
        skip(uint128(MAXTIME * 2));
        lockedFPIS.increaseAmount(20e18, 0);

        lockedFPIS.toggleContractPause();
        vm.expectRevert(FPISLocker.OperationIsPaused.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_increaseUnlockTime() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(WEEK)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(lockedFPIS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        uint128 newUnlockTimestamp = unlockTimestamp + 2 * uint128(WEEK);
        vm.expectEmit(true, true, true, true, address(lockedFPIS));
        emit Deposit(bob, bob, newUnlockTimestamp, 0, INCREASE_UNLOCK_TIME, block.timestamp);
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(50e18, 50e18);
        hoax(bob);
        lockedFPIS.increaseUnlockTime(newUnlockTimestamp, 0);

        assertEq(token.balanceOf(address(lockedFPIS)), 50e18);
        assertEq(token.balanceOf(bob), 50e18);
        lockId = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.lockedById(bob, lockId);
        lBalance.end = newUnlockTimestamp;
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        // This is for the unreachable check on line 569
        // hoax(alice);
        // vm.expectRevert(FPISLocker.NoExistingLockFound.selector);
        // lockedFPIS.increaseUnlockTime(newUnlockTimestamp, 0);

        hoax(bob);
        vm.expectRevert(FPISLocker.MustBeInAFutureEpochWeek.selector);
        lockedFPIS.increaseUnlockTime(unlockTimestamp - 1, 0);

        hoax(bob);
        vm.expectRevert(FPISLocker.LockCanOnlyBeUpToFourYears.selector);
        lockedFPIS.increaseUnlockTime(uint128(block.timestamp) + uint128(MAXTIME) * 2, 0);

        hoax(bob);
        vm.expectRevert(FPISLocker.LockExpired.selector);
        skip(uint128(MAXTIME * 2));
        lockedFPIS.increaseUnlockTime(newUnlockTimestamp, 0);

        lockedFPIS.toggleContractPause();
        vm.expectRevert(FPISLocker.OperationIsPaused.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_withdraw() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 60e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(lockedFPIS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 idOfFirstLock = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, idOfFirstLock);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        uint8 numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        uint8 numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 1);
        assertEq(numOfFloxContributorLocks, 0);

        vm.expectRevert(FPISLocker.LockDidNotExpire.selector);
        hoax(bob);
        lockedFPIS.withdraw(0);

        skip(uint128(MAXTIME));
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit Withdraw(bob, bob, 50e18, block.timestamp);
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(50e18, 0);
        hoax(bob);
        lockedFPIS.withdraw(0);

        assertEq(token.balanceOf(address(lockedFPIS)), 0);
        lBalance.amount = 0;
        lBalance.end = 0;
        idOfFirstLock = lockedFPIS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = lockedFPIS.locked(bob, idOfFirstLock);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 0);

        lockedFPIS.setFloxContributor(alice, true);
        hoax(alice);
        token.approve(address(lockedFPIS), 1e19);
        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(alice);
        lockedFPIS.createLock(bob, 10 ** 19, unlockTimestamp);

        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 1);

        lockedFPIS.activateEmergencyUnlock();
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit Withdraw(bob, bob, 10 ** 19, block.timestamp);
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(10 ** 19, 0);
        hoax(bob);
        lockedFPIS.withdraw(0);

        numOfUserLocks = lockedFPIS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = lockedFPIS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 0);

        lockedFPIS.toggleContractPause();
        vm.expectRevert(FPISLocker.OperationIsPaused.selector);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_withdrawAfterEmergencyUnlock() public {
        lockedFPISSetup();

        // Approve Alice
        hoax(alice);
        token.approve(address(lockedFPIS), 1000 gwei);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + LOCK_SECONDS_MAX_TWO_THIRDS) / uint128(WEEK)) * uint128(WEEK);

        // Lock Alice
        hoax(alice);
        (uint128 _lockIndex, uint256 _lockId) = lockedFPIS.createLock(alice, 1000 gwei, unlockTimestamp);

        // Approve Bob
        hoax(bob);
        token.approve(address(lockedFPIS), 1000 gwei);
        unlockTimestamp = ((uint128(block.timestamp) + LOCK_SECONDS_MAX) / uint128(WEEK)) * uint128(WEEK);

        // Lock Bob
        hoax(bob);
        lockedFPIS.createLock(bob, 1000 gwei, unlockTimestamp);

        console.log("--------- After createLocks ---------");

        // Skip ahead some time so you are at ~0.6665X for Alice. Bob should be at ~0.99975X
        _warpToAndRollOne(((uint128(block.timestamp) + LOCK_SECONDS_MAX_ONE_THIRD) / uint128(WEEK)) * uint128(WEEK));
        console.log("--------- After 1st warp ---------");

        // Print some info and check Alice's lFPIS balance. Should be ~666.5 gwei (half of 1.333 gwei)
        uint256 _expectedLFPISAlice = lockedFPISUtils.getCrudeExpectedLFPISUser(alice);
        uint256 _actualLFPISAlice = lockedFPIS.balanceOf(alice);
        console.log("_lockIndex: ", _lockIndex);
        console.log("lockedFPIS.getLockIndexById(alice, _lockId): ", lockedFPIS.getLockIndexById(alice, _lockId));
        console.log("_lockId: ", _lockId);
        console.log("lockedFPIS.indicesToIds(alice, 0): ", lockedFPIS.indicesToIds(alice, 0));
        console.log("numLocks: ", lockedFPIS.numLocks(alice));
        console.log("Alice actual lFPIS balance: ", _actualLFPISAlice);
        console.log("Alice expected lFPIS balance: ", _expectedLFPISAlice);
        console.log("Alice actual lFPIS balance: ", _actualLFPISAlice);
        assertApproxEqRel(_expectedLFPISAlice, _actualLFPISAlice, 0.01e18, "Alice's _expectedLFPIS vs _actualLFPIS");
        assertApproxEqRel(lockedFPIS.balanceOf(alice), 666.5 gwei, 0.01e18, "Alice's initial lFPIS balance");
        assertApproxEqRel(lockedFPIS.balanceOfAllLocksAtBlock(alice, block.number), 666.5 gwei, 0.01e18, "Alice's initial lFPIS balance (balanceOfAllLocksAtBlock)");
        assertApproxEqRel(lockedFPIS.balanceOfAllLocksAtTime(alice, block.timestamp), 666.5 gwei, 0.01e18, "Alice's initial lFPIS balance (balanceOfAllLocksAtTime)");
        assertApproxEqRel(lockedFPIS.balanceOfOneLockAtBlock(alice, 0, block.number), 666.5 gwei, 0.01e18, "Alice's initial lFPIS balance (balanceOfOneLockAtBlock)");
        assertApproxEqRel(lockedFPIS.balanceOfOneLockAtTime(alice, 0, block.timestamp), 666.5 gwei, 0.01e18, "Alice's initial lFPIS balance (balanceOfOneLockAtTime)");

        // Print Bob info. Should be at ~0.99975X
        uint256 _expectedLFPISBob = lockedFPISUtils.getCrudeExpectedLFPISUser(bob);
        uint256 _actualLFPISBob = lockedFPIS.balanceOf(bob);
        console.log("Bob expected lFPIS balance: ", _expectedLFPISBob);
        console.log("Bob actual lFPIS balance: ", _actualLFPISBob);
        assertApproxEqRel(_expectedLFPISBob, _actualLFPISBob, 0.01e18, "Bob's _expectedLFPIS vs _actualLFPIS");
        assertApproxEqRel(lockedFPIS.balanceOf(bob), 999.75 gwei, 0.01e18, "Bob's initial lFPIS balance");

        // Emergency unlock
        hoax(lockedFPIS.lockerAdmin());
        lockedFPIS.activateEmergencyUnlock();

        // Have Alice withdraw
        hoax(alice);
        lockedFPIS.withdraw(_lockIndex);
        console.log("--------- After withdraw() ---------");

        // Print some info and check Alice's lFPIS balance. Should be 0 now
        _expectedLFPISAlice = lockedFPISUtils.getCrudeExpectedLFPISUser(alice);
        _actualLFPISAlice = lockedFPIS.balanceOf(alice);
        console.log("Alice expected lFPIS balance: ", _expectedLFPISAlice);
        console.log("Alice actual lFPIS balance: ", _actualLFPISAlice);
        assertEq(_expectedLFPISAlice, 0, "Alice's _expectedLFPIS should be 0");
        assertEq(_actualLFPISAlice, 0, "Alice's _actualLFPIS should be 0");
        assertEq(lockedFPIS.balanceOf(alice), 0, "Alice's post-withdrawal lFPIS balance");
        assertEq(lockedFPIS.balanceOfAllLocksAtBlock(alice, block.number), 0, "Alice's post-withdrawal lFPIS balance (balanceOfAllLocksAtBlock)");
        assertEq(lockedFPIS.balanceOfAllLocksAtTime(alice, block.timestamp), 0, "Alice's post-withdrawal lFPIS balance (balanceOfAllLocksAtTime)");
        // assertEq(lockedFPIS.balanceOfOneLockAtBlock(alice, 0, block.number), 0, "Alice's post-withdrawal lFPIS balance (balanceOfOneLockAtBlock)");
        // assertEq(lockedFPIS.balanceOfOneLockAtTime(alice, 0, block.timestamp), 0, "Alice's post-withdrawal lFPIS balance (balanceOfOneLockAtTime)");

        // Print Bob info. Should be equal to the amount of deposited FPIS, due to emergency unlock
        _expectedLFPISBob = 1000 gwei * 3330 / 10_000;
        _actualLFPISBob = lockedFPIS.balanceOf(bob);
        console.log("Bob expected lFPIS balance: ", _expectedLFPISBob);
        console.log("Bob actual lFPIS balance: ", _actualLFPISBob);
        assertApproxEqRel(_expectedLFPISBob, _actualLFPISBob, 0.01e18, "Bob's _expectedLFPIS vs _actualLFPIS");
        assertApproxEqRel(lockedFPIS.balanceOf(bob), 1000 gwei * 3330 / 10_000, 0.01e18, "Bob's initial lFPIS balance");

        // Get the current supply and sum
        uint256 totalSupply = lockedFPIS.totalSupply();
        Point memory currGlobalPoint = lockedFPIS.getLastGlobalPoint();
        console.log("---Global Point (now)---");
        console.log("Global Point bias (now): ", currGlobalPoint.bias);
        console.log("Global Point slope (now): ", currGlobalPoint.slope);
        console.log("Global Point ts (now): ", currGlobalPoint.ts);
        console.log("Global Point blk (now): ", currGlobalPoint.blk);
        console.log("Global Point fpisAmt (now): ", currGlobalPoint.fpisAmt);
        console.log("totalSupply(): ", totalSupply);

        // Assert the balanceOf and totalSupply match
        assertEq(_actualLFPISAlice + _actualLFPISBob, totalSupply, "balanceOf and totalSupply (after withdrawal)");

        // Skip ahead some time so you are at ~2X for Bob
        _warpToAndRollOne(((uint128(block.timestamp) + LOCK_SECONDS_MAX_ONE_THIRD) / uint128(WEEK)) * uint128(WEEK));
        console.log("--------- After 2nd warp ---------");

        // Print Bob info
        _expectedLFPISBob = 1000 gwei * 3330 / 10_000;
        _actualLFPISBob = lockedFPIS.balanceOf(bob);
        console.log("Bob expected lFPIS balance: ", _expectedLFPISBob);
        console.log("Bob actual lFPIS balance: ", _actualLFPISBob);
        assertApproxEqRel(_expectedLFPISBob, _actualLFPISBob, 0.01e18, "Bob's _expectedLFPIS vs _actualLFPIS");
        assertApproxEqRel(lockedFPIS.balanceOf(bob), 1000 gwei * 3330 / 10_000, 0.01e18, "Bob's initial lFPIS balance");

        // Get the current supply and sum again
        totalSupply = lockedFPIS.totalSupply();
        currGlobalPoint = lockedFPIS.getLastGlobalPoint();
        console.log("---Global Point (now)---");
        console.log("Global Point bias (now): ", currGlobalPoint.bias);
        console.log("Global Point slope (now): ", currGlobalPoint.slope);
        console.log("Global Point ts (now): ", currGlobalPoint.ts);
        console.log("Global Point blk (now): ", currGlobalPoint.blk);
        console.log("Global Point fpisAmt (now): ", currGlobalPoint.fpisAmt);
        console.log("totalSupply(): ", totalSupply);

        // Assert the balanceOf and totalSupply match
        assertEq(_actualLFPISBob, totalSupply, "balanceOf and totalSupply (after 2nd warp)");
    }

    function test_balanceOfOneLockAtTime() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        (uint128 _newIndex, uint256 _newLockId) = lockedFPIS.createLock(bob, 50e18, unlockTimestamp);
        console.log("_newLockId: ", _newLockId);

        // Check the user's epoch
        uint256 currUserEpoch = lockedFPIS.userPointEpoch(bob, _newLockId);
        console.log("user epoch: ", currUserEpoch);
        assertEq(currUserEpoch, 1, "currUserEpoch should be 1");

        uint256 _testEpoch = lockedFPIS.findUserTimestampEpoch(bob, _newIndex, block.timestamp + 1);
        console.log("_testEpoch: ", _testEpoch);

        // Min method
        {
            uint256 _min = 0;
            uint256 _max = lockedFPIS.userPointEpoch(bob, _newLockId);
            for (uint256 i; i < 128;) {
                // Will be always enough for 128-bit numbers
                if (_min >= _max) {
                    break;
                }
                uint256 _mid = (_min + _max + 1) / 2;
                Point memory _thePoint = lockedFPIS.getUserPointAtEpoch(bob, _newIndex, _mid);

                if (_thePoint.ts <= block.timestamp + 1) {
                    _min = _mid;
                } else {
                    _max = _mid - 1;
                }

                unchecked {
                    ++i;
                }
            }
            console.log("_min epoch: ", _min);
        }

        uint256 initialVotingPower = lockedFPIS.balanceOfOneLockAtTime(bob, _newIndex, block.timestamp + 1);
        uint256 halfwayVotingPower = lockedFPIS.balanceOfOneLockAtTime(bob, _newIndex, block.timestamp + uint128(MAXTIME) / 2);
        uint256 finalVotingPower = lockedFPIS.balanceOfOneLockAtTime(bob, _newIndex, unlockTimestamp);

        assertGt(initialVotingPower, halfwayVotingPower, "initialVotingPower <= halfwayVotingPower");
        assertGt(halfwayVotingPower, finalVotingPower, "halfwayVotingPower <= finalVotingPower");
    }

    function test_balanceOfOneLockAtBlock() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 10e18, unlockTimestamp);

        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block0 = block.number;
        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block1 = block.number;
        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block2 = block.number;

        uint256 initialVotingPower = lockedFPIS.balanceOfOneLockAtBlock(bob, 0, block0);
        uint256 halfwayVotingPower = lockedFPIS.balanceOfOneLockAtBlock(bob, 0, block1);
        uint256 finalVotingPower = lockedFPIS.balanceOfOneLockAtBlock(bob, 0, block2);
        uint256 noVotingPower = lockedFPIS.balanceOfOneLockAtBlock(bob, 0, 1);

        assertGt(initialVotingPower, halfwayVotingPower);
        assertGt(halfwayVotingPower, finalVotingPower);
        assertEq(noVotingPower, 0);

        vm.expectRevert(FPISLocker.InvalidBlockNumber.selector);
        lockedFPIS.balanceOfOneLockAtBlock(bob, 0, block.number + 1);
    }

    function test_totalSupply() public {
        lockedFPISSetup();

        lockedFPIS.checkpoint();

        hoax(bob);
        token.approve(address(lockedFPIS), 60e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);
        hoax(alice);
        token.approve(address(lockedFPIS), 60e18);
        hoax(alice);
        lockedFPIS.createLock(alice, 50e18, unlockTimestamp);
        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);
        lockedFPIS.checkpoint();
        lockedFPIS.totalSupply(block.timestamp);
        uint256 timestampToValidate = block.timestamp;

        vm.roll(block.number + 10);
        skip(uint128(WEEK) * 2);
        lockedFPIS.checkpoint();

        uint256 votingPowerBob = lockedFPIS.balanceOfOneLockAtTime(bob, 0, timestampToValidate);
        uint256 votingPowerAlice = lockedFPIS.balanceOfOneLockAtTime(alice, 0, timestampToValidate);
        uint256 totalSupply = lockedFPIS.totalSupply(timestampToValidate);

        assertEq(totalSupply, votingPowerBob + votingPowerAlice);
    }

    function test_MultiLockOperation() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, unlockTimestamp);

        hoax(alice);
        token.approve(address(lockedFPIS), 100e18);
        hoax(alice);
        lockedFPIS.createLock(alice, 40e18, unlockTimestamp);

        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);

        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);

        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestamp);

        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);

        uint256 ts = block.timestamp;

        assertEq(token.balanceOf(address(lockedFPIS)), 100e18);
        assertLe(lockedFPIS.balanceOfOneLockAtTime(alice, 0, ts), lockedFPIS.balanceOfOneLockAtTime(bob, 0, ts));
        assertLe(lockedFPIS.balanceOfOneLockAtTime(alice, 1, ts), lockedFPIS.balanceOfOneLockAtTime(bob, 0, ts));
        assertGt(lockedFPIS.balanceOfOneLockAtTime(alice, 0, ts) + lockedFPIS.balanceOfOneLockAtTime(alice, 1, ts), lockedFPIS.balanceOfOneLockAtTime(bob, 0, ts));
        assertEq(lockedFPIS.numLocks(bob), 1);
        assertEq(lockedFPIS.numLocks(alice), 2);

        vm.roll(block.number + 100);
        skip(uint256(uint128(MAXTIME)) / 2);
        lockedFPIS.checkpoint();

        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);

        hoax(alice);
        lockedFPIS.increaseUnlockTime(unlockTimestamp, 1);

        vm.roll(block.number + 10);
        skip(uint256(uint128(MAXTIME)) / 2);
        lockedFPIS.checkpoint();
        ts = block.timestamp;

        vm.expectRevert(FPISLocker.LockExpired.selector);
        hoax(bob);
        lockedFPIS.increaseUnlockTime(unlockTimestamp, 0);

        vm.expectRevert(FPISLocker.LockCanOnlyBeUpToFourYears.selector);
        hoax(alice);
        lockedFPIS.increaseUnlockTime(uint128(block.timestamp) + uint128(MAXTIME) * 2, 1);

        uint256 initialLockId = lockedFPIS.indicesToIds(alice, 1);
        (int128 initialLock,) = lockedFPIS.locked(alice, initialLockId);

        hoax(alice);
        lockedFPIS.withdraw(0);

        uint256 migratedLockId = lockedFPIS.indicesToIds(alice, 0);
        (int128 migratedLock,) = lockedFPIS.locked(alice, migratedLockId);

        assertEq(initialLock, migratedLock);
        assertEq(lockedFPIS.numLocks(alice), 1);

        uint256 increasedLockId = lockedFPIS.indicesToIds(alice, 0);
        hoax(alice);
        lockedFPIS.increaseAmount(10e18, 0);

        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);
        lockedFPIS.checkpoint();
        ts = block.timestamp;

        (int128 increasedLock,) = lockedFPIS.lockedById(alice, increasedLockId);

        assertGt(increasedLock, migratedLock);
    }

    function test_GlobalStateUpdates() public {
        lockedFPISSetup();

        uint256 startTimestamp = 100e18;
        skip(startTimestamp - block.timestamp);
        assertEq(block.timestamp, startTimestamp);

        uint256 amount = 50e18;
        uint256 minScaledAmount = 1665e16; // This is 50e18 * 0.333

        token.mint(address(this), amount * 10);

        token.approve(address(lockedFPIS), amount * 5);

        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        lockedFPIS.createLock(address(this), 40e18, unlockTimestamp);
        vm.roll(42);
        lockedFPIS.increaseAmount(10e18, 0);

        uint256 lockId = lockedFPIS.indicesToIds(address(this), 0);
        (int128 retrievedAmount, uint256 retrievedEnd) = lockedFPIS.locked(address(this), lockId);
        assertEq(retrievedAmount, int128(uint128(amount)));
        assertEq(retrievedEnd, unlockTimestamp);
        assertEq(lockedFPIS.userPointEpoch(address(this), lockId), 2);

        assertEq(lockedFPIS.epoch(), 2);
        (int128 retrievedBias, int128 retrievedSlope, uint256 retrievedTs, uint256 retrievedBlk, uint256 retrievedFpisAmt) = lockedFPIS.userPointHistory(address(this), lockId, 2);
        assertEq(retrievedBias, 66_430_568_239_465_148_800); // 1665e16 + slopeFromBelow * (unlockTimestamp - startTimestamp)
        assertEq(retrievedSlope, 396_372_399_797); // 50e18 * VOTE_WEIGHT_MULTIPLIER / MAXTIM / MAX_BASIS_POINTS_INT128
        assertEq(retrievedTs, 100e18);
        assertEq(retrievedBlk, 42);
        assertEq(retrievedFpisAmt, 50e18);

        (retrievedBias, retrievedSlope, retrievedTs, retrievedBlk, retrievedFpisAmt) = lockedFPIS.pointHistory(2);
        assertEq(retrievedBias, 66_430_568_239_465_148_800); // 1665e16 + slopeFromBelow * (unlockTimestamp - startTimestamp)
        assertEq(retrievedSlope, 396_372_399_797); // 50e18 * VOTE_WEIGHT_MULTIPLIER / MAXTIM / MAX_BASIS_POINTS_INT128
        assertEq(retrievedTs, 100e18);
        assertEq(retrievedBlk, 42);
        assertEq(retrievedFpisAmt, 50e18);

        assertEq(lockedFPIS.totalFPISSupply(), amount);

        skip(7 * 86_400);
        vm.roll(50);

        lockedFPIS.createLock(address(this), amount, unlockTimestamp);
        assertEq(lockedFPIS.epoch(), 4);
        lockId = lockedFPIS.indicesToIds(address(this), 1);
        (retrievedBias, retrievedSlope, retrievedTs, retrievedBlk, retrievedFpisAmt) = lockedFPIS.userPointHistory(address(this), lockId, 1);
        assertEq(retrievedBias, 66_190_842_212_067_923_200); // 1665e16 + slopeFromBelow * (unlockTimestamp - startTimestamp)
        assertEq(retrievedSlope, 396_372_399_797); // 50e18 * VOTE_WEIGHT_MULTIPLIER / MAXTIM / MAX_BASIS_POINTS_INT128
        assertEq(retrievedTs, 100e18 + (7 * 86_400));
        assertEq(retrievedBlk, 50);
        assertEq(retrievedFpisAmt, 50e18);

        (retrievedBias, retrievedSlope, retrievedTs, retrievedBlk, retrievedFpisAmt) = lockedFPIS.pointHistory(4);
        assertEq(retrievedBias, 132_381_684_424_135_846_400);
        assertEq(retrievedSlope, 792_744_799_594);
        assertEq(retrievedTs, 100e18 + (7 * 86_400));
        assertEq(retrievedBlk, 50);
        assertEq(retrievedFpisAmt, 100e18);

        assertEq(lockedFPIS.totalFPISSupply(), amount * 2);
    }

    function _warpToAndRollOne(uint256 _newTs) public {
        vm.warp(_newTs);
        vm.roll(block.number + 1);
    }

    function testZach_CreateLockTsBounds() public {
        lockedFPISSetup();
        vm.warp(block.timestamp + 100);

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        (, uint128 latest) = lockedFPIS.getCreateLockTsBounds();
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, latest);

        uint256 lockId = lockedFPIS.indicesToIds(bob, 0);
        (, uint256 end) = lockedFPIS.locked(bob, lockId);
        console.log("end: ", end);
        console.log("latest: ", latest);
        assertEq(end, latest);
        // assertLt(end, latest);
    }

    function testZach_NoPastBalance() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 60e18);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, uint128(block.timestamp + 1 weeks));

        lockedFPIS.balanceOfAllLocksAtTime(bob, block.timestamp - 1);
    }

    function testZach_TotalSupplyBug() public {
        lockedFPISSetup();
        lockedFPIS.checkpoint();
        uint256 targetTs = block.timestamp;

        (uint128 earliest,) = lockedFPIS.getCreateLockTsBounds();
        vm.warp(earliest + 21 days - 1);

        uint256 supply = lockedFPIS.totalSupply(targetTs);
        assertEq(supply, 0);

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, uint128(block.timestamp + 1));

        uint256 newSupply = lockedFPIS.totalSupply(targetTs);
        // TODO: Needs a fix -- fixed
        assertEq(newSupply, 0); // After fix, this should be used
            // assertEq(newSupply, 52_294_436_120_623_716_839);
    }

    function test_balanceFunctionsReturningFpisAmountWhenEmergencyUnlockIsActive() public {
        lockedFPISSetup();

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        hoax(alice);
        token.approve(address(lockedFPIS), 50e18);

        hoax(bob);
        lockedFPIS.createLock(bob, 20e18, uint128(block.timestamp + 10 weeks));
        hoax(bob);
        lockedFPIS.createLock(bob, 22e18, uint128(block.timestamp + 20 weeks));
        hoax(alice);
        lockedFPIS.createLock(alice, 16e18, uint128(block.timestamp + 30 weeks));

        lockedFPIS.activateEmergencyUnlock();

        assertEq(lockedFPIS.balanceOf(bob), 42e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOf(alice), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAt(bob, block.number - 10), 42e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAt(bob, block.number + 10), 42e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAt(alice, block.number - 10), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAt(alice, block.number + 10), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtBlock(bob, block.number - 10), 42e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtBlock(bob, block.number + 10), 42e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtBlock(alice, block.number - 10), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtBlock(alice, block.number + 10), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtTime(bob, block.timestamp + 4 weeks), 42e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtTime(bob, block.timestamp - 4 weeks), 42e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtTime(alice, block.timestamp + 4 weeks), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfAllLocksAtTime(alice, block.timestamp - 4 weeks), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtBlock(bob, 0, block.number - 10), 20e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtBlock(bob, 0, block.number + 10), 20e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtBlock(bob, 1, block.number - 10), 22e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtBlock(bob, 1, block.number + 10), 22e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtBlock(alice, 0, block.number - 10), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtBlock(alice, 0, block.number + 10), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtTime(bob, 0, block.timestamp + 4 weeks), 20e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtTime(bob, 0, block.timestamp - 4 weeks), 20e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtTime(bob, 1, block.timestamp + 4 weeks), 22e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtTime(bob, 1, block.timestamp - 4 weeks), 22e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtTime(alice, 0, block.timestamp + 4 weeks), 16e18 * 3330 / 10_000);
        assertEq(lockedFPIS.balanceOfOneLockAtTime(alice, 0, block.timestamp - 4 weeks), 16e18 * 3330 / 10_000);

        assertEq(lockedFPIS.lockedEnd(bob, 0), block.timestamp);
        assertEq(lockedFPIS.lockedEnd(bob, 1), block.timestamp);
        assertEq(lockedFPIS.lockedEnd(alice, 0), block.timestamp);

        assertEq(lockedFPIS.totalSupply(), 58e18 * 3330 / 10_000);
        assertEq(lockedFPIS.totalSupply(block.timestamp + 4 weeks), 58e18 * 3330 / 10_000);
        assertEq(lockedFPIS.totalSupply(block.timestamp - 4 weeks), 58e18 * 3330 / 10_000);

        assertEq(lockedFPIS.totalSupplyAt(block.number), 58e18 * 3330 / 10_000);
        assertEq(lockedFPIS.totalSupplyAt(block.number - 10), 58e18 * 3330 / 10_000);
    }

    function test_supplyAtReverts() public {
        lockedFPISSetup();

        IlFPISStructs.Point memory point = IlFPISStructs.Point(0, 0, 42, 0, 0);

        vm.expectRevert(FPISLocker.InvalidTimestamp.selector);
        lockedFPIS.supplyAt(point, 16);

        hoax(bob);
        token.approve(address(lockedFPIS), 50e18);
        hoax(bob);
        lockedFPIS.createLock(bob, 50e18, uint128(block.timestamp + uint128(MAXTIME)));

        lockedFPIS.activateEmergencyUnlock();

        uint256 retrievedCurrentSupply = lockedFPIS.supplyAt(point, block.timestamp);
        uint256 retrievedPastSupply = lockedFPIS.supplyAt(point, block.timestamp - 1 weeks);
        uint256 retrievedFutureSupply = lockedFPIS.supplyAt(point, block.timestamp + 1 weeks);

        uint256 expectedCurrentSupply = (50e18 * 3330) / 10_000;

        assertEq(retrievedCurrentSupply, expectedCurrentSupply);
        assertEq(retrievedPastSupply, expectedCurrentSupply);
        assertEq(retrievedFutureSupply, expectedCurrentSupply);
    }

    function test_convertToFXSAndLockInVeFXS() public {
        lockedFPISSetup();

        fxs.mint(address(lockedFPIS), 100e18);

        uint256 initialTimestamp = lockedFPIS.FXS_CONVERSION_START_TIMESTAMP() - (MAXTIME_UINT256 / 2);
        vm.warp(initialTimestamp);
        vm.roll(100);

        uint128 unlockTimestampMax = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampHalf = ((uint128(block.timestamp) + uint128(MAXTIME / 2)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampMin = ((uint128(block.timestamp) + uint128(MAXTIME / 4)) / uint128(WEEK)) * uint128(WEEK);

        hoax(alice);
        token.approve(address(lockedFPIS), 100e18);
        hoax(alice);
        (uint128 lockIndex0,) = lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 20e18, unlockTimestampHalf);
        hoax(alice);
        lockedFPIS.createLock(alice, 30e18, unlockTimestampMin);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);

        vm.expectRevert(abi.encodeWithSelector(FPISLocker.FxsConversionNotActive.selector, initialTimestamp, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP()));
        hoax(alice);
        lockedFPIS.convertToFXSAndLockInVeFXS(false, 0, 0);

        vm.warp(lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.roll(200);

        uint256 initialFPISBalanceAlice = token.balanceOf(alice);
        uint256 initialFPISBalanceAggregator = token.balanceOf(bob);
        uint256 initialFXSBalance = fxs.balanceOf(alice);
        uint256 initialLockedFXSBalance = vestedFXS.balanceOfLockedFxs(alice);
        uint8 initialContributorCreatedLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);

        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 10e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(90e18, 80e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit ConvertLockToVeFxs(alice, 10e18, 10e19 / 25, 0, 0);
        hoax(alice);
        (uint128 createdVeFxsLock,) = lockedFPIS.convertToFXSAndLockInVeFXS(true, lockIndex0, 0);

        assertEq(initialFPISBalanceAlice, token.balanceOf(alice));
        assertEq(initialFPISBalanceAggregator + 10e18, token.balanceOf(bob));
        assertEq(initialFXSBalance, fxs.balanceOf(alice));
        assertEq(initialLockedFXSBalance + 10e19 / 25, vestedFXS.balanceOfLockedFxs(alice));
        assertEq(initialContributorCreatedLocks + 1, vestedFXS.numberOfFloxContributorCreatedLocks(alice));

        hoax(alice);
        lockedFPIS.convertToFXSAndLockInVeFXS(true, lockIndex0, 0);

        initialFPISBalanceAlice = token.balanceOf(alice);
        initialFPISBalanceAggregator = token.balanceOf(bob);
        initialFXSBalance = fxs.balanceOf(alice);
        initialLockedFXSBalance = vestedFXS.balanceOfLockedFxs(alice);
        initialContributorCreatedLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);

        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 10e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(70e18, 60e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit ConvertLockToVeFxs(alice, 10e18, 10e19 / 25, 0, createdVeFxsLock);
        hoax(alice);
        (uint128 existingVeFxsLock,) = lockedFPIS.convertToFXSAndLockInVeFXS(false, lockIndex0, createdVeFxsLock);

        assertEq(initialFPISBalanceAlice, token.balanceOf(alice));
        assertEq(initialFPISBalanceAggregator + 10e18, token.balanceOf(bob));
        assertEq(initialFXSBalance, fxs.balanceOf(alice));
        assertEq(initialLockedFXSBalance + 10e19 / 25, vestedFXS.balanceOfLockedFxs(alice));
        assertEq(initialContributorCreatedLocks, vestedFXS.numberOfFloxContributorCreatedLocks(alice));
        assertEq(existingVeFxsLock, createdVeFxsLock);

        vm.expectRevert(FPISLocker.LockExpired.selector);
        hoax(alice);
        lockedFPIS.convertToFXSAndLockInVeFXS(true, 2, 0);

        vm.expectRevert(FPISLocker.NoExistingLockFound.selector);
        hoax(alice);
        lockedFPIS.convertToFXSAndLockInVeFXS(true, 8, 0);

        unlockTimestampMin = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(alice);
        (lockIndex0,) = lockedFPIS.createLock(alice, 10e18, unlockTimestampMin);

        vm.expectRevert(abi.encodeWithSelector(FPISLocker.VeFxsLockCannotBeShorterThanLFpisLock.selector, unlockTimestampMax, unlockTimestampMin));
        hoax(alice);
        lockedFPIS.convertToFXSAndLockInVeFXS(false, lockIndex0, createdVeFxsLock);

        fxs.mint(bob, 100e18);
        hoax(bob);
        fxs.approve(address(vestedFXS), 100e18);
        vestedFXS.setFloxContributor(bob, true);

        for (uint8 i; i < 8 - vestedFXS.numberOfFloxContributorCreatedLocks(alice);) {
            hoax(bob);
            vestedFXS.createLock(alice, 10e18, unlockTimestampMax);
        }
        vm.expectRevert(FPISLocker.MaximumVeFxsContributorLocksReached.selector);
        hoax(alice);
        lockedFPIS.convertToFXSAndLockInVeFXS(true, 0, 0);

        lockedFPIS.toggleContractPause();

        vm.expectRevert(FPISLocker.MaximumVeFxsContributorLocksReached.selector);
        hoax(alice);
        lockedFPIS.convertToFXSAndLockInVeFXS(true, 0, 0);
    }

    function test_bulkConvertToFXSAndLockInVeFXS() public {
        console2.log("<<< Setup >>>");
        lockedFPISSetup();

        fxs.mint(address(lockedFPIS), 100e18);

        uint256 initialTimestamp = lockedFPIS.FXS_CONVERSION_START_TIMESTAMP() - (MAXTIME_UINT256 / 2);
        vm.warp(initialTimestamp);
        vm.roll(100);

        uint128 unlockTimestampMax = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampHalf = ((uint128(block.timestamp) + uint128(MAXTIME / 2)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampMin = ((uint128(block.timestamp) + uint128(MAXTIME / 4)) / uint128(WEEK)) * uint128(WEEK);

        console2.log("<<< CreateLocks >>>");
        hoax(alice);
        token.approve(address(lockedFPIS), 100e18);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 20e18, unlockTimestampHalf);
        hoax(alice);
        lockedFPIS.createLock(alice, 30e18, unlockTimestampMin);
        hoax(alice);
        lockedFPIS.createLock(alice, 5e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 5e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);

        uint128[] memory inputLockIndices = new uint128[](2);
        uint128[] memory outputLockIndices = new uint128[](2);

        console2.log("<<< Bulk converts #1 >>>");
        vm.expectRevert(abi.encodeWithSelector(FPISLocker.FxsConversionNotActive.selector, initialTimestamp, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP()));
        hoax(alice);
        lockedFPIS.bulkConvertToFXSAndLockInVeFXS(false, inputLockIndices, outputLockIndices);

        console2.log("<<< Bulk converts #2 >>>");
        lockedFPIS.toggleContractPause();
        vm.expectRevert(FPISLocker.OperationIsPaused.selector);
        hoax(alice);
        lockedFPIS.bulkConvertToFXSAndLockInVeFXS(false, inputLockIndices, outputLockIndices);
        lockedFPIS.toggleContractPause();

        vm.warp(lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.roll(200);

        console2.log("<<< Bulk converts #3 >>>");
        uint128[] memory oversizedInputLockIndices = new uint128[](3);
        vm.expectRevert(FPISLocker.ArrayLengthMismatch.selector);
        hoax(alice);
        lockedFPIS.bulkConvertToFXSAndLockInVeFXS(false, oversizedInputLockIndices, outputLockIndices);

        inputLockIndices[0] = 0;
        inputLockIndices[1] = 3;

        uint256 initialFPISBalanceAlice = token.balanceOf(alice);
        uint256 initialFPISBalanceAggregator = token.balanceOf(bob);
        uint256 initialFXSBalance = fxs.balanceOf(alice);
        uint256 initialLockedFXSBalance = vestedFXS.balanceOfLockedFxs(alice);
        uint8 initialContributorCreatedLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);

        console2.log("<<< Bulk Converts #4 >>>");
        uint128[] memory emptyInputLockIndices = new uint128[](0);
        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 10e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(80e18, 70e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit ConvertLockToVeFxs(alice, 10e18, 4e18, 0, 0);
        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 5e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(70e18, 65e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit ConvertLockToVeFxs(alice, 5e18, 2e18, 3, 1);
        hoax(alice);
        lockedFPIS.bulkConvertToFXSAndLockInVeFXS(true, inputLockIndices, emptyInputLockIndices);

        console2.log("<<< Asserts >>>");
        assertEq(initialFPISBalanceAlice, token.balanceOf(alice));
        assertEq(initialFPISBalanceAggregator + 15e18, token.balanceOf(bob));
        assertEq(initialFXSBalance, fxs.balanceOf(alice));
        assertEq(initialLockedFXSBalance + 6e18, vestedFXS.balanceOfLockedFxs(alice));
        assertEq(initialContributorCreatedLocks + 2, vestedFXS.numberOfFloxContributorCreatedLocks(alice));

        initialFPISBalanceAlice = token.balanceOf(alice);
        initialFPISBalanceAggregator = token.balanceOf(bob);
        initialFXSBalance = fxs.balanceOf(alice);
        initialLockedFXSBalance = vestedFXS.balanceOfLockedFxs(alice);
        initialContributorCreatedLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);

        outputLockIndices[0] = 1;
        outputLockIndices[1] = 1;

        console2.log("<<< Bulk Converts #5 >>>");
        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 10e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(65e18, 55e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit ConvertLockToVeFxs(alice, 10e18, 4e18, 0, 1);
        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 5e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(55e18, 50e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit ConvertLockToVeFxs(alice, 5e18, 2e18, 0, 1);
        hoax(alice);
        lockedFPIS.bulkConvertToFXSAndLockInVeFXS(false, inputLockIndices, outputLockIndices);

        assertEq(initialFPISBalanceAlice, token.balanceOf(alice));
        assertEq(initialFPISBalanceAggregator + 15e18, token.balanceOf(bob));
        assertEq(initialFXSBalance, fxs.balanceOf(alice));
        assertEq(initialLockedFXSBalance + 6e18, vestedFXS.balanceOfLockedFxs(alice));
        assertEq(initialContributorCreatedLocks, vestedFXS.numberOfFloxContributorCreatedLocks(alice));

        vm.expectRevert(FPISLocker.ArrayNotEmpty.selector);
        hoax(alice);
        lockedFPIS.bulkConvertToFXSAndLockInVeFXS(true, inputLockIndices, outputLockIndices);

        inputLockIndices[0] = 42;

        vm.expectRevert(FPISLocker.LockIDNotInUse.selector);
        hoax(alice);
        lockedFPIS.bulkConvertToFXSAndLockInVeFXS(false, inputLockIndices, outputLockIndices);
    }

    function test_getCrudeExpectedLFPISMultiLock() public {
        lockedFPISSetup();

        // Get two crude LFPISs one at a time
        uint256 _expectedLFPISOneLockNum1 = fpisLockerUtils.getCrudeExpectedLFPISOneLock(1e18, uint128(WEEK));
        uint256 _expectedLFPISOneLockNum2 = fpisLockerUtils.getCrudeExpectedLFPISOneLock(10e18, uint128(LOCK_SECONDS_MAX_TWO_THIRDS));

        // Get two crude LFPISs in one call
        int128[] memory _fpisAmounts = new int128[](2);
        _fpisAmounts[0] = 1e18;
        _fpisAmounts[1] = 10e18;
        uint128[] memory _lockSecsU128 = new uint128[](2);
        _lockSecsU128[0] = uint128(WEEK);
        _lockSecsU128[1] = uint128(LOCK_SECONDS_MAX_TWO_THIRDS);
        uint256 _expectedLFPISMultiLock = fpisLockerUtils.getCrudeExpectedLFPISMultiLock(_fpisAmounts, _lockSecsU128);

        // The sums of both methods should match, and it should be about 21 LFPIS
        assertEq(_expectedLFPISOneLockNum1 + _expectedLFPISOneLockNum2, _expectedLFPISMultiLock, "Sums of getCrudeExpectedLFPIS methods should match");
        assertApproxEqRel(_expectedLFPISOneLockNum1 + _expectedLFPISOneLockNum2, 10.333e18, ONE_PCT_DELTA, "Sum of getCrudeExpectedLFPISOneLock should be 10.333 LFPIS");
        assertApproxEqRel(_expectedLFPISMultiLock, 10.333e18, ONE_PCT_DELTA, "Sum of getCrudeExpectedLFPISMultiLock should be 10.333 LFPIS");
    }

    function test_withdrawLockAsFxs() public {
        lockedFPISSetup();

        fxs.mint(address(lockedFPIS), 100e18);

        uint256 initialTimestamp = lockedFPIS.FXS_CONVERSION_START_TIMESTAMP() - (MAXTIME_UINT256 / 2);
        vm.warp(initialTimestamp);
        vm.roll(100);

        uint128 unlockTimestampMax = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampHalf = ((uint128(block.timestamp) + uint128(MAXTIME / 2)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampMin = ((uint128(block.timestamp) + uint128(MAXTIME / 4)) / uint128(WEEK)) * uint128(WEEK);

        hoax(alice);
        token.approve(address(lockedFPIS), 100e18);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 20e18, unlockTimestampHalf);
        hoax(alice);
        lockedFPIS.createLock(alice, 30e18, unlockTimestampMin);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);

        vm.expectRevert(abi.encodeWithSelector(FPISLocker.FxsConversionNotActive.selector, initialTimestamp, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP()));
        hoax(alice);
        lockedFPIS.withdrawLockAsFxs(0);

        lockedFPIS.toggleContractPause();
        vm.expectRevert(abi.encodeWithSelector(FPISLocker.FxsConversionNotActive.selector, initialTimestamp, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP()));
        hoax(alice);
        lockedFPIS.withdrawLockAsFxs(0);
        lockedFPIS.toggleContractPause();

        vm.warp(lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.roll(200);

        uint256 initialFPISBalanceAlice = token.balanceOf(alice);
        uint256 initialFPISBalanceAggregator = token.balanceOf(bob);
        uint256 initialFXSBalance = fxs.balanceOf(alice);
        uint256 initialContractFXSBalance = fxs.balanceOf(address(lockedFPIS));

        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 30e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(90e18, 60e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit WithdrawAsFxs(alice, alice, 30e18, 12e18);
        hoax(alice);
        lockedFPIS.withdrawLockAsFxs(2);

        assertEq(initialFPISBalanceAlice, token.balanceOf(alice));
        assertEq(initialFPISBalanceAggregator + 30e18, token.balanceOf(bob));
        assertEq(initialFXSBalance + 12e18, fxs.balanceOf(alice));
        assertEq(initialContractFXSBalance - 12e18, fxs.balanceOf(address(lockedFPIS)));

        vm.expectRevert(FPISLocker.LockDidNotExpire.selector);
        hoax(alice);
        lockedFPIS.withdrawLockAsFxs(0);

        hoax(address(lockedFPIS));
        fxs.transfer(bob, 88e18);

        vm.expectRevert(FPISLocker.InsufficientFxsBalance.selector);
        hoax(alice);
        lockedFPIS.withdrawLockAsFxs(1);
    }

    function test_bulkWithdrawLockAsFxs() public {
        lockedFPISSetup();

        fxs.mint(address(lockedFPIS), 100e18);

        uint256 initialTimestamp = lockedFPIS.FXS_CONVERSION_START_TIMESTAMP() - (MAXTIME_UINT256 / 2);
        vm.warp(initialTimestamp);
        vm.roll(100);

        uint128 unlockTimestampMax = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampHalf = ((uint128(block.timestamp) + uint128(MAXTIME / 2)) / uint128(WEEK)) * uint128(WEEK);
        uint128 unlockTimestampMin = ((uint128(block.timestamp) + uint128(MAXTIME / 4)) / uint128(WEEK)) * uint128(WEEK);

        hoax(alice);
        token.approve(address(lockedFPIS), 100e18);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 20e18, unlockTimestampHalf);
        hoax(alice);
        lockedFPIS.createLock(alice, 30e18, unlockTimestampMin);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);
        hoax(alice);
        lockedFPIS.createLock(alice, 10e18, unlockTimestampMax);

        vm.expectRevert(abi.encodeWithSelector(FPISLocker.FxsConversionNotActive.selector, initialTimestamp, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP()));
        hoax(alice);
        lockedFPIS.withdrawLockAsFxs(0);

        lockedFPIS.toggleContractPause();
        vm.expectRevert(abi.encodeWithSelector(FPISLocker.FxsConversionNotActive.selector, initialTimestamp, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP()));
        hoax(alice);
        lockedFPIS.withdrawLockAsFxs(0);
        lockedFPIS.toggleContractPause();

        vm.warp(lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.roll(200);

        uint256 initialFPISBalanceAlice = token.balanceOf(alice);
        uint256 initialFPISBalanceAggregator = token.balanceOf(bob);
        uint256 initialFXSBalance = fxs.balanceOf(alice);
        uint256 initialContractFXSBalance = fxs.balanceOf(address(lockedFPIS));

        uint128[] memory inputLockIndices = new uint128[](2);

        inputLockIndices[0] = 1;
        inputLockIndices[1] = 2;

        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 20e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(90e18, 70e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit WithdrawAsFxs(alice, alice, 20e18, 8e18);
        vm.expectEmit(true, true, false, true, address(lockedFPIS));
        emit Withdraw(alice, bob, 30e18, lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());
        vm.expectEmit(false, false, false, true, address(lockedFPIS));
        emit Supply(70e18, 40e18);
        vm.expectEmit(true, false, false, true, address(lockedFPIS));
        emit WithdrawAsFxs(alice, alice, 30e18, 12e18);
        hoax(alice);
        lockedFPIS.bulkWithdrawLockAsFxs(inputLockIndices);

        assertEq(initialFPISBalanceAlice, token.balanceOf(alice));
        assertEq(initialFPISBalanceAggregator + 50e18, token.balanceOf(bob));
        assertEq(initialFXSBalance + 20e18, fxs.balanceOf(alice));
        assertEq(initialContractFXSBalance - 20e18, fxs.balanceOf(address(lockedFPIS)));

        inputLockIndices[0] = 42;

        vm.expectRevert(FPISLocker.LockIDNotInUse.selector);
        hoax(alice);
        lockedFPIS.bulkWithdrawLockAsFxs(inputLockIndices);
    }

    function test_GetLongestLock() public {
        lockedFPISSetup();

        uint128 numOfLocks = 8;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        uint128 longestLockIndex;
        LockedBalance memory lock;

        for (uint128 i; i < numOfLocks;) {
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            token.approve(address(lockedFPIS), 1000e18 * (i + 1));
            hoax(bob);
            lockedFPIS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);

            if (i == numOfLocks - 1) {
                lock = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
                longestLockIndex = i;
            }

            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        (FPISLockerUtils.LockedBalance memory longestLock, uint128 retrievedLongestLockIndex) = fpisLockerUtils.getLongestLock(bob);

        assertEq(retrievedLongestLockIndex, longestLockIndex);
        assertEq(longestLock.amount, lock.amount);
        assertEq(longestLock.end, lock.end);
    }

    function test_GetLongestLockBulk() public {
        lockedFPISSetup();

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
            token.approve(address(lockedFPIS), 1000e18 * (i + 1));
            hoax(bob);
            lockedFPIS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);

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
            token.approve(address(lockedFPIS), 1000e18 * (i + 1));
            hoax(alice);
            lockedFPIS.createLock(alice, 1000e18 * (i + 1), unlockTimestamp);

            if (i == secondNumOfLocks - 1) {
                secondLock = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            }

            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        FPISLockerUtils.LongestLock[] memory longestLocks = fpisLockerUtils.getLongestLockBulk(addresses);

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

    function test_FPISLockerBulkGetAllLocksOf() public {
        lockedFPISSetup();

        address[] memory addresses = new address[](2);
        addresses[0] = address(bob);
        addresses[1] = address(alice);
        uint128 firstNumOfLocks = 8;
        uint128 secondNumOfLocks = 5;
        uint128 unlockTimestamp = uint128(((block.timestamp + uint128(WEEK * 2)) / uint128(WEEK)) * uint128(WEEK));
        LockedBalance[] memory firstLocks = new LockedBalance[](firstNumOfLocks);
        LockedBalance[] memory secondLocks = new LockedBalance[](secondNumOfLocks);

        console2.log("<<< createLocks #1 >>>");
        for (uint128 i; i < firstNumOfLocks;) {
            console2.log("  --- mint");
            token.mint(bob, 1000e18 * (i + 1));
            hoax(bob);
            console2.log("  --- approve");
            token.approve(address(lockedFPIS), 1000e18 * (i + 1));
            hoax(bob);
            console2.log("  --- createLock");
            lockedFPIS.createLock(bob, 1000e18 * (i + 1), unlockTimestamp);
            firstLocks[i] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        console2.log("<<< createLocks #2 >>>");
        for (uint128 i; i < secondNumOfLocks;) {
            console2.log("  --- mint");
            token.mint(alice, 1000e18 * (i + 1));
            hoax(alice);
            console2.log("  --- approve");
            token.approve(address(lockedFPIS), 1000e18 * (i + 1));
            hoax(alice);
            console2.log("  --- createLock");
            lockedFPIS.createLock(alice, 1000e18 * (i + 1), unlockTimestamp);
            secondLocks[i] = LockedBalance({ amount: int128(1000e18 * (i + 1)), end: unlockTimestamp });
            unlockTimestamp += uint128(WEEK);

            unchecked {
                ++i;
            }
        }

        console2.log("<<< getDetailedUserLockInfoBulk >>>");
        DetailedUserLockInfo[] memory bulkLockInfos = lockedFPISUtils.getDetailedUserLockInfoBulk(addresses);

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

    function testZach_IncorrectLockIndex() public {
        lockedFPISSetup();
        fxs.mint(address(lockedFPIS), 100e18);
        fxs.mint(address(alice), 100e18);

        vm.startPrank(alice);

        uint128 unlockTime = uint128(lockedFPIS.FXS_CONVERSION_START_TIMESTAMP() + 100 days);
        vm.warp(unlockTime - 4 * 52 weeks);

        // first, create two veFXS locks
        fxs.approve(address(vestedFXS), 100e18);
        (uint128 vefxsIndex0,) = vestedFXS.createLock(alice, 50e18, unlockTime);
        (uint128 vefxsIndex1,) = vestedFXS.createLock(alice, 50e18, unlockTime);

        // then, create one FPIS lock
        token.approve(address(lockedFPIS), 100e18);
        (uint128 fpisIndex0,) = lockedFPIS.createLock(alice, 10e18, unlockTime);

        // skip until the time when conversion is allowed
        vm.warp(lockedFPIS.FXS_CONVERSION_START_TIMESTAMP());

        // move the fpis lock into the index 1 veFXS lock
        (uint128 vefxsLockIndex,) = lockedFPIS.convertToFXSAndLockInVeFXS(false, fpisIndex0, vefxsIndex1);

        // it returns an index of 1
        assertEq(vefxsLockIndex, 1);

        // but it's actually the correct index 1 lock that's incremented
        (int128 amount,) = vestedFXS.locked(alice, vestedFXS.indicesToIds(alice, vefxsIndex1));
        assertEq(uint128(amount), 50e18 + 10e18 * 4 / 10);
    }

    function testZach_EmergencyInflateBalance() public {
        lockedFPISSetup();

        vm.startPrank(bob);
        token.approve(address(lockedFPIS), 100e18);
        uint128 unlockTimestamp = uint128(block.timestamp + 2 weeks);
        lockedFPIS.createLock(bob, 100e18, unlockTimestamp);
        vm.stopPrank();

        assertEq(lockedFPIS.balanceOf(bob), 33_870_719_970_826_908_826);

        vm.prank(lockedFPIS.lockerAdmin());
        lockedFPIS.activateEmergencyUnlock();

        assertEq(lockedFPIS.balanceOf(bob), 33_300_000_000_000_000_000);
    }
}
