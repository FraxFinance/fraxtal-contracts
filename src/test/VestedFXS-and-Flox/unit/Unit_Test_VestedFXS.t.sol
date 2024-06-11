// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS, IveFXSStructs } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_VestedFXS is BaseTestVeFXS {
    function vestedFXSSetup() public {
        console.log("vestedFXSSetup() called");
        super.defaultSetup();

        // Mint FXS to the test users
        token.mint(alice, 100e18);
        token.mint(bob, 100e18);
    }

    function test_commitTransferOwnership() public {
        vestedFXSSetup();

        vm.expectEmit(false, false, false, true);
        emit CommitOwnership(bob);
        vestedFXS.commitTransferOwnership(bob);
        assertEq(vestedFXS.futureAdmin(), bob);

        vm.expectRevert(VestedFXS.AdminOnly.selector);
        hoax(bob);
        vestedFXS.commitTransferOwnership(bob);
    }

    function test_acceptTransferOwnership() public {
        vestedFXSSetup();

        vestedFXS.commitTransferOwnership(bob);
        vm.expectEmit(false, false, false, true);
        emit ApplyOwnership(bob);
        hoax(bob);
        vestedFXS.acceptTransferOwnership();
        assertEq(vestedFXS.admin(), bob);

        vm.expectRevert(VestedFXS.FutureAdminOnly.selector);
        hoax(alice);
        vestedFXS.acceptTransferOwnership();

        // Since the future admin needs to accept the transfer, it is extremely unlikely this happens, but just in case..
        hoax(bob);
        vestedFXS.commitTransferOwnership(address(0));
        hoax(address(0));
        vm.expectRevert(VestedFXS.AdminNotSet.selector);
        vestedFXS.acceptTransferOwnership();
    }

    function test_toggleContractPause() public {
        vestedFXSSetup();

        assertFalse(vestedFXS.isPaused());

        vm.expectEmit(false, false, false, true);
        emit ContractPause(true);
        vestedFXS.toggleContractPause();

        assertTrue(vestedFXS.isPaused());

        vm.expectEmit(false, false, false, true);
        emit ContractPause(false);
        vestedFXS.toggleContractPause();

        vm.expectRevert(VestedFXS.AdminOnly.selector);
        hoax(bob);
        vestedFXS.toggleContractPause();
    }

    function test_activateEmergencyUnlock() public {
        vestedFXSSetup();

        assertEq(vestedFXS.emergencyUnlockActive(), false);

        vestedFXS.activateEmergencyUnlock();
        assertEq(vestedFXS.emergencyUnlockActive(), true);

        vm.expectRevert(VestedFXS.AdminOnly.selector);
        hoax(bob);
        vestedFXS.activateEmergencyUnlock();
    }

    function test_setFloxContributor() public {
        vestedFXSSetup();

        assertEq(vestedFXS.floxContributors(bob), false);

        vm.expectEmit(true, true, false, true);
        emit FloxContributorUpdate(bob, true);
        vestedFXS.setFloxContributor(bob, true);
        assertEq(vestedFXS.floxContributors(bob), true);

        vm.expectEmit(true, true, false, true);
        emit FloxContributorUpdate(bob, false);
        vestedFXS.setFloxContributor(bob, false);
        assertEq(vestedFXS.floxContributors(bob), false);

        vm.expectRevert(VestedFXS.AdminOnly.selector);
        hoax(bob);
        vestedFXS.setFloxContributor(bob, true);
    }

    function test_recoverIERC20() public {
        vestedFXSSetup();

        MintableBurnableTestERC20 unrelated = new MintableBurnableTestERC20("unrelated", "UNR");
        unrelated.mint(address(vestedFXS), 100e18);

        assertEq(unrelated.balanceOf(address(vestedFXS)), 100e18);
        vestedFXS.recoverIERC20(address(unrelated), 100e18);
        assertEq(unrelated.balanceOf(address(vestedFXS)), 0);

        vm.expectRevert(VestedFXS.AdminOnly.selector);
        hoax(bob);
        vestedFXS.recoverIERC20(address(unrelated), 100e18);

        vm.expectRevert(VestedFXS.UnableToRecoverFXS.selector);
        vestedFXS.recoverIERC20(address(token), 100e18);
    }

    function test_getLastUserSlope() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 5 * 10 ** 19);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 5 * 10 ** 19, unlockTimestamp);

        int128 slope = vestedFXS.getLastUserSlope(bob, 0);
        int128 expectedSlope = (int128(5 * 10 ** 19) * VOTE_WEIGHT_MULTIPLIER) / MAXTIME;

        assertEq(slope, expectedSlope);
    }

    function test_userPointHistoryTs() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 5 * 10 ** 19);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 5 * 10 ** 19, unlockTimestamp);

        assertEq(block.timestamp, vestedFXS.userPointHistoryTs(bob, 0, 1));
    }

    function test_lockedEnd() public {
        vestedFXSSetup();

        assertEq(vestedFXS.lockedEnd(bob, 0), 0);

        hoax(bob);
        token.approve(address(vestedFXS), 5 * 10 ** 19);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 5 * 10 ** 19, unlockTimestamp);

        assertEq(unlockTimestamp, vestedFXS.lockedEnd(bob, 0));
    }

    function test_createLock() public {
        vestedFXSSetup();

        assertEq(token.balanceOf(address(vestedFXS)), 0);
        LockedBalance memory lBalance;
        lBalance.amount = 0;
        lBalance.end = 0;
        LockedBalance memory retrievedBalance;
        uint256 lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        uint8 numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        uint8 numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 0);

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(bob, bob, unlockTimestamp, 50e18, CREATE_LOCK_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(0, 50e18);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(vestedFXS)), 50e18);
        assertEq(token.balanceOf(bob), 50e18);
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 1);
        assertEq(numOfFloxContributorLocks, 0);
        assertFalse(vestedFXS.isLockCreatedByFloxContributor(bob, lockId));

        vestedFXS.setFloxContributor(bob, true);
        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(alice, bob, unlockTimestamp, 50e18, CREATE_LOCK_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(50e18, 100e18);
        hoax(bob);
        vestedFXS.createLock(alice, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(vestedFXS)), 100e18);
        assertEq(token.balanceOf(bob), 0);
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        lockId = vestedFXS.indicesToIds(alice, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.lockedById(alice, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 1);
        assertTrue(vestedFXS.isLockCreatedByFloxContributor(alice, lockId));

        vestedFXS.setFloxContributor(bob, false);
        vm.expectRevert(VestedFXS.NotLockingForSelfOrFloxContributor.selector);
        hoax(bob);
        vestedFXS.createLock(alice, 50e18, unlockTimestamp);

        vm.expectRevert(VestedFXS.MinLockAmount.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 0, unlockTimestamp);

        vm.expectRevert(VestedFXS.MustBeInAFutureEpochWeek.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, uint128(block.timestamp - 1));

        vm.expectRevert(VestedFXS.LockCanOnlyBeUpToFourYears.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, uint128(block.timestamp) + uint128(MAXTIME) * 2);

        token.mint(alice, 10 ** 21);
        hoax(alice);
        token.approve(address(vestedFXS), 10 ** 21);
        uint128 currentLocks = vestedFXS.numberOfUserCreatedLocks(alice);
        uint8 maximumUserLocks = 8;
        for (uint128 i = currentLocks; i < maximumUserLocks / 2;) {
            hoax(alice);
            vestedFXS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 4);
        assertEq(numOfFloxContributorLocks, 1);

        vestedFXS.setFloxContributor(bob, true);
        token.mint(bob, 10 ** 21);
        hoax(bob);
        token.approve(address(vestedFXS), 10 ** 21);
        currentLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);
        uint8 maximumContributorLocks = 8;
        for (uint128 i = currentLocks; i < maximumContributorLocks / 2;) {
            hoax(bob);
            vestedFXS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 4);
        assertEq(numOfFloxContributorLocks, 4);

        currentLocks = vestedFXS.numberOfUserCreatedLocks(alice);
        for (uint128 i = currentLocks; i < maximumUserLocks;) {
            hoax(alice);
            vestedFXS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 8);
        assertEq(numOfFloxContributorLocks, 4);

        currentLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);
        for (uint128 i = currentLocks; i < maximumContributorLocks;) {
            hoax(bob);
            vestedFXS.createLock(alice, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(alice);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(alice);
        assertEq(numOfUserLocks, 8);
        assertEq(numOfFloxContributorLocks, 8);

        vm.expectRevert(VestedFXS.MaximumUserLocksReached.selector);
        hoax(alice);
        vestedFXS.createLock(alice, 50e18, unlockTimestamp);

        vm.expectRevert(VestedFXS.MaximumFloxContributorLocksReached.selector);
        hoax(bob);
        vestedFXS.createLock(alice, 50e18, unlockTimestamp);

        currentLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        for (uint128 i = currentLocks; i < maximumUserLocks;) {
            hoax(bob);
            vestedFXS.createLock(bob, 50e18, unlockTimestamp);

            unchecked {
                ++i;
            }
        }

        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        uint8 finalNumOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 8);
        assertEq(numOfFloxContributorLocks, finalNumOfFloxContributorLocks);

        vm.expectRevert(VestedFXS.MaximumUserLocksReached.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        vestedFXS.setFloxContributor(alice, true);
        hoax(alice);
        token.approve(address(vestedFXS), 50e18);
        hoax(alice);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfFloxContributorLocks, finalNumOfFloxContributorLocks + 1);

        vestedFXS.toggleContractPause();
        vm.expectRevert(VestedFXS.OperationIsPaused.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_depositFor() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(vestedFXS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        hoax(alice);
        token.approve(address(vestedFXS), 20e18);
        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(bob, alice, unlockTimestamp, 20e18, DEPOSIT_FOR_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(50e18, 70e18);
        hoax(alice);
        vestedFXS.depositFor(bob, 20e18, 0);

        assertEq(token.balanceOf(address(vestedFXS)), 70e18);
        assertEq(token.balanceOf(alice), 80e18);
        assertEq(token.balanceOf(bob), 50e18);
        lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, lockId);
        lBalance.amount = 70e18;
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        vm.expectRevert(VestedFXS.MinLockAmount.selector);
        vestedFXS.depositFor(bob, 0, 0);

        vm.expectRevert(VestedFXS.NoExistingLockFound.selector);
        vestedFXS.depositFor(alice, 20e18, 0);

        vm.expectRevert(VestedFXS.LockExpired.selector);
        skip(uint128(MAXTIME * 2));
        vestedFXS.depositFor(bob, 20e18, 0);

        vestedFXS.toggleContractPause();
        vm.expectRevert(VestedFXS.OperationIsPaused.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_increaseAmount() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 70e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(vestedFXS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(bob, bob, unlockTimestamp, 20e18, INCREASE_LOCK_AMOUNT, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(50e18, 70e18);
        hoax(bob);
        vestedFXS.increaseAmount(20e18, 0);

        assertEq(token.balanceOf(address(vestedFXS)), 70e18);
        assertEq(token.balanceOf(bob), 30e18);
        lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, lockId);
        lBalance.amount = 70e18;
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        vm.expectRevert(VestedFXS.MinLockAmount.selector);
        vestedFXS.increaseAmount(0, 0);

        hoax(alice);
        vm.expectRevert(VestedFXS.NoExistingLockFound.selector);
        vestedFXS.increaseAmount(20e18, 0);

        hoax(bob);
        vm.expectRevert(VestedFXS.LockExpired.selector);
        skip(uint128(MAXTIME * 2));
        vestedFXS.increaseAmount(20e18, 0);

        vestedFXS.toggleContractPause();
        vm.expectRevert(VestedFXS.OperationIsPaused.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_increaseUnlockTime() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(WEEK)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(vestedFXS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, lockId);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        uint128 newUnlockTimestamp = unlockTimestamp + 2 * uint128(WEEK);
        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(bob, bob, newUnlockTimestamp, 0, INCREASE_UNLOCK_TIME, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(50e18, 50e18);
        hoax(bob);
        vestedFXS.increaseUnlockTime(newUnlockTimestamp, 0);

        assertEq(token.balanceOf(address(vestedFXS)), 50e18);
        assertEq(token.balanceOf(bob), 50e18);
        lockId = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.lockedById(bob, lockId);
        lBalance.end = newUnlockTimestamp;
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);

        // This is for the unreachable check on line 569
        // hoax(alice);
        // vm.expectRevert(VestedFXS.NoExistingLockFound.selector);
        // vestedFXS.increaseUnlockTime(newUnlockTimestamp, 0);

        hoax(bob);
        vm.expectRevert(VestedFXS.MustBeInAFutureEpochWeek.selector);
        vestedFXS.increaseUnlockTime(unlockTimestamp - 1, 0);

        hoax(bob);
        vm.expectRevert(VestedFXS.LockCanOnlyBeUpToFourYears.selector);
        vestedFXS.increaseUnlockTime(uint128(block.timestamp) + uint128(MAXTIME) * 2, 0);

        hoax(bob);
        vm.expectRevert(VestedFXS.LockExpired.selector);
        skip(uint128(MAXTIME * 2));
        vestedFXS.increaseUnlockTime(newUnlockTimestamp, 0);

        vestedFXS.toggleContractPause();
        vm.expectRevert(VestedFXS.OperationIsPaused.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_withdraw() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 60e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        assertEq(token.balanceOf(address(vestedFXS)), 50e18);
        LockedBalance memory lBalance;
        lBalance.amount = 50e18;
        lBalance.end = unlockTimestamp;
        LockedBalance memory retrievedBalance;
        uint256 idOfFirstLock = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, idOfFirstLock);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        uint8 numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        uint8 numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 1);
        assertEq(numOfFloxContributorLocks, 0);

        vm.expectRevert(VestedFXS.LockDidNotExpire.selector);
        hoax(bob);
        vestedFXS.withdraw(0);

        skip(uint128(MAXTIME));
        vm.expectEmit(true, false, false, true, address(vestedFXS));
        emit Withdraw(bob, bob, 50e18, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(50e18, 0);
        hoax(bob);
        vestedFXS.withdraw(0);

        assertEq(token.balanceOf(address(vestedFXS)), 0);
        lBalance.amount = 0;
        lBalance.end = 0;
        idOfFirstLock = vestedFXS.indicesToIds(bob, 0);
        (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.locked(bob, idOfFirstLock);
        assertEq(retrievedBalance.amount, lBalance.amount);
        assertEq(retrievedBalance.end, lBalance.end);
        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 0);

        vestedFXS.setFloxContributor(alice, true);
        hoax(alice);
        token.approve(address(vestedFXS), 1e19);
        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(alice);
        vestedFXS.createLock(bob, 10 ** 19, unlockTimestamp);

        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 1);

        vestedFXS.activateEmergencyUnlock();
        vm.expectEmit(true, false, false, true, address(vestedFXS));
        emit Withdraw(bob, bob, 10 ** 19, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(10 ** 19, 0);
        hoax(bob);
        vestedFXS.withdraw(0);

        numOfUserLocks = vestedFXS.numberOfUserCreatedLocks(bob);
        numOfFloxContributorLocks = vestedFXS.numberOfFloxContributorCreatedLocks(bob);
        assertEq(numOfUserLocks, 0);
        assertEq(numOfFloxContributorLocks, 0);

        vestedFXS.toggleContractPause();
        vm.expectRevert(VestedFXS.OperationIsPaused.selector);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);
    }

    function test_withdrawAfterEmergencyUnlock() public {
        vestedFXSSetup();

        // Approve Alice
        hoax(alice);
        token.approve(address(vestedFXS), 1000 gwei);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + LOCK_SECONDS_3X) / uint128(WEEK)) * uint128(WEEK);

        // Lock Alice
        hoax(alice);
        (uint128 _lockIndex, uint256 _lockId) = vestedFXS.createLock(alice, 1000 gwei, unlockTimestamp);

        // Approve Bob
        hoax(bob);
        token.approve(address(vestedFXS), 1000 gwei);
        unlockTimestamp = ((uint128(block.timestamp) + LOCK_SECONDS_4X) / uint128(WEEK)) * uint128(WEEK);

        // Lock Bob
        hoax(bob);
        vestedFXS.createLock(bob, 1000 gwei, unlockTimestamp);

        console.log("--------- After createLocks ---------");

        // Skip ahead some time so you are at ~2X for Alice. Bob should be at ~3X
        _warpToAndRollOne(((uint128(block.timestamp) + LOCK_SECONDS_2X) / uint128(WEEK)) * uint128(WEEK));
        console.log("--------- After 1st warp ---------");

        // Print some info and check Alice's veFXS balance. Should be ~2000 gwei (2X)
        uint256 _expectedVeFXSAlice = vestedFXSUtils.getCrudeExpectedVeFXSUser(alice);
        uint256 _actualVeFXSAlice = vestedFXS.balanceOf(alice);
        console.log("_lockIndex: ", _lockIndex);
        console.log("vestedFXS.getLockIndexById(alice, _lockId): ", vestedFXS.getLockIndexById(alice, _lockId));
        console.log("_lockId: ", _lockId);
        console.log("vestedFXS.indicesToIds(alice, 0): ", vestedFXS.indicesToIds(alice, 0));
        console.log("numLocks: ", vestedFXS.numLocks(alice));
        console.log("Alice actual veFXS balance: ", _actualVeFXSAlice);
        console.log("Alice expected veFXS balance: ", _expectedVeFXSAlice);
        console.log("Alice actual veFXS balance: ", _actualVeFXSAlice);
        assertApproxEqRel(_expectedVeFXSAlice, _actualVeFXSAlice, 0.01e18, "Alice's _expectedVeFXS vs _actualVeFXS");
        assertApproxEqRel(vestedFXS.balanceOf(alice), 2000 gwei, 0.01e18, "Alice's initial veFXS balance");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtBlock(alice, block.number), 2000 gwei, 0.01e18, "Alice's initial veFXS balance (balanceOfAllLocksAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtTime(alice, block.timestamp), 2000 gwei, 0.01e18, "Alice's initial veFXS balance (balanceOfAllLocksAtTime)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtBlock(alice, 0, block.number), 2000 gwei, 0.01e18, "Alice's initial veFXS balance (balanceOfOneLockAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtTime(alice, 0, block.timestamp), 2000 gwei, 0.01e18, "Alice's initial veFXS balance (balanceOfOneLockAtTime)");

        // Print Bob info. Should be at ~3X
        uint256 _expectedVeFXSBob = vestedFXSUtils.getCrudeExpectedVeFXSUser(bob);
        uint256 _actualVeFXSBob = vestedFXS.balanceOf(bob);
        console.log("Bob expected veFXS balance: ", _expectedVeFXSBob);
        console.log("Bob actual veFXS balance: ", _actualVeFXSBob);
        assertApproxEqRel(_expectedVeFXSBob, _actualVeFXSBob, 0.01e18, "Bob's _expectedVeFXS vs _actualVeFXS");
        assertApproxEqRel(vestedFXS.balanceOf(bob), 3000 gwei, 0.01e18, "Bob's initial veFXS balance");

        // Emergency unlock
        hoax(vestedFXS.admin());
        vestedFXS.activateEmergencyUnlock();

        // Have Alice withdraw
        hoax(alice);
        vestedFXS.withdraw(_lockIndex);
        console.log("--------- After withdraw() ---------");

        // Print some info and check Alice's veFXS balance. Should be 0 now
        _expectedVeFXSAlice = vestedFXSUtils.getCrudeExpectedVeFXSUser(alice);
        _actualVeFXSAlice = vestedFXS.balanceOf(alice);
        console.log("Alice expected veFXS balance: ", _expectedVeFXSAlice);
        console.log("Alice actual veFXS balance: ", _actualVeFXSAlice);
        assertEq(_expectedVeFXSAlice, 0, "Alice's _expectedVeFXS should be 0");
        assertEq(_actualVeFXSAlice, 0, "Alice's _actualVeFXS should be 0");
        assertEq(vestedFXS.balanceOf(alice), 0, "Alice's post-withdrawal veFXS balance");
        assertEq(vestedFXS.balanceOfAllLocksAtBlock(alice, block.number), 0, "Alice's post-withdrawal veFXS balance (balanceOfAllLocksAtBlock)");
        assertEq(vestedFXS.balanceOfAllLocksAtTime(alice, block.timestamp), 0, "Alice's post-withdrawal veFXS balance (balanceOfAllLocksAtTime)");
        // assertEq(vestedFXS.balanceOfOneLockAtBlock(alice, 0, block.number), 0, "Alice's post-withdrawal veFXS balance (balanceOfOneLockAtBlock)");
        // assertEq(vestedFXS.balanceOfOneLockAtTime(alice, 0, block.timestamp), 0, "Alice's post-withdrawal veFXS balance (balanceOfOneLockAtTime)");

        // Print Bob info. Should be equal to the amount of deposited FXS, due to emergency unlock
        _expectedVeFXSBob = 1000 gwei;
        _actualVeFXSBob = vestedFXS.balanceOf(bob);
        console.log("Bob expected veFXS balance: ", _expectedVeFXSBob);
        console.log("Bob actual veFXS balance: ", _actualVeFXSBob);
        assertApproxEqRel(_expectedVeFXSBob, _actualVeFXSBob, 0.01e18, "Bob's _expectedVeFXS vs _actualVeFXS");
        assertApproxEqRel(vestedFXS.balanceOf(bob), 1000 gwei, 0.01e18, "Bob's initial veFXS balance");

        // Get the current supply and sum
        uint256 totalSupply = vestedFXS.totalSupply();
        Point memory currGlobalPoint = vestedFXS.getLastGlobalPoint();
        console.log("---Global Point (now)---");
        console.log("Global Point bias (now): ", currGlobalPoint.bias);
        console.log("Global Point slope (now): ", currGlobalPoint.slope);
        console.log("Global Point ts (now): ", currGlobalPoint.ts);
        console.log("Global Point blk (now): ", currGlobalPoint.blk);
        console.log("Global Point fxsAmt (now): ", currGlobalPoint.fxsAmt);
        console.log("totalSupply(): ", totalSupply);

        // Assert the balanceOf and totalSupply match
        assertEq(_actualVeFXSAlice + _actualVeFXSBob, totalSupply, "balanceOf and totalSupply (after withdrawal)");

        // Skip ahead some time so you are at ~2X for Bob
        _warpToAndRollOne(((uint128(block.timestamp) + LOCK_SECONDS_2X) / uint128(WEEK)) * uint128(WEEK));
        console.log("--------- After 2nd warp ---------");

        // Print Bob info
        _expectedVeFXSBob = 1000 gwei;
        _actualVeFXSBob = vestedFXS.balanceOf(bob);
        console.log("Bob expected veFXS balance: ", _expectedVeFXSBob);
        console.log("Bob actual veFXS balance: ", _actualVeFXSBob);
        assertApproxEqRel(_expectedVeFXSBob, _actualVeFXSBob, 0.01e18, "Bob's _expectedVeFXS vs _actualVeFXS");
        assertApproxEqRel(vestedFXS.balanceOf(bob), 1000 gwei, 0.01e18, "Bob's initial veFXS balance");

        // Get the current supply and sum again
        totalSupply = vestedFXS.totalSupply();
        currGlobalPoint = vestedFXS.getLastGlobalPoint();
        console.log("---Global Point (now)---");
        console.log("Global Point bias (now): ", currGlobalPoint.bias);
        console.log("Global Point slope (now): ", currGlobalPoint.slope);
        console.log("Global Point ts (now): ", currGlobalPoint.ts);
        console.log("Global Point blk (now): ", currGlobalPoint.blk);
        console.log("Global Point fxsAmt (now): ", currGlobalPoint.fxsAmt);
        console.log("totalSupply(): ", totalSupply);

        // Assert the balanceOf and totalSupply match
        assertEq(_actualVeFXSBob, totalSupply, "balanceOf and totalSupply (after 2nd warp)");
    }

    function test_balanceOfOneLockAtTime() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        (uint128 _newIndex, uint256 _newLockId) = vestedFXS.createLock(bob, 50e18, unlockTimestamp);
        console.log("_newLockId: ", _newLockId);

        // Check the user's epoch
        uint256 currUserEpoch = vestedFXS.userPointEpoch(bob, _newLockId);
        console.log("user epoch: ", currUserEpoch);
        assertEq(currUserEpoch, 1, "currUserEpoch should be 1");

        uint256 _testEpoch = vestedFXS.findUserTimestampEpoch(bob, _newIndex, block.timestamp + 1);
        console.log("_testEpoch: ", _testEpoch);

        // Min method
        {
            uint256 _min = 0;
            uint256 _max = vestedFXS.userPointEpoch(bob, _newLockId);
            for (uint256 i; i < 128;) {
                // Will be always enough for 128-bit numbers
                if (_min >= _max) {
                    break;
                }
                uint256 _mid = (_min + _max + 1) / 2;
                Point memory _thePoint = vestedFXS.getUserPointAtEpoch(bob, _newIndex, _mid);

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

        uint256 initialVotingPower = vestedFXS.balanceOfOneLockAtTime(bob, _newIndex, block.timestamp + 1);
        uint256 halfwayVotingPower = vestedFXS.balanceOfOneLockAtTime(bob, _newIndex, block.timestamp + uint128(MAXTIME) / 2);
        uint256 finalVotingPower = vestedFXS.balanceOfOneLockAtTime(bob, _newIndex, unlockTimestamp);

        assertGt(initialVotingPower, halfwayVotingPower, "initialVotingPower <= halfwayVotingPower");
        assertGt(halfwayVotingPower, finalVotingPower, "halfwayVotingPower <= finalVotingPower");
    }

    function test_balanceOfOneLockAtBlock() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 10e18, unlockTimestamp);

        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block0 = block.number;
        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block1 = block.number;
        skip(uint128(MAXTIME / 4));
        vm.roll(block.number + 100);
        uint256 block2 = block.number;

        uint256 initialVotingPower = vestedFXS.balanceOfOneLockAtBlock(bob, 0, block0);
        uint256 halfwayVotingPower = vestedFXS.balanceOfOneLockAtBlock(bob, 0, block1);
        uint256 finalVotingPower = vestedFXS.balanceOfOneLockAtBlock(bob, 0, block2);
        uint256 noVotingPower = vestedFXS.balanceOfOneLockAtBlock(bob, 0, 1);

        assertGt(initialVotingPower, halfwayVotingPower);
        assertGt(halfwayVotingPower, finalVotingPower);
        assertEq(noVotingPower, 0);

        vm.expectRevert(VestedFXS.InvalidBlockNumber.selector);
        vestedFXS.balanceOfOneLockAtBlock(bob, 0, block.number + 1);
    }

    function test_totalSupply() public {
        vestedFXSSetup();

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
        vestedFXS.totalSupply(block.timestamp);
        uint256 timestampToValidate = block.timestamp;

        vm.roll(block.number + 10);
        skip(uint128(WEEK) * 2);
        vestedFXS.checkpoint();

        uint256 votingPowerBob = vestedFXS.balanceOfOneLockAtTime(bob, 0, timestampToValidate);
        uint256 votingPowerAlice = vestedFXS.balanceOfOneLockAtTime(alice, 0, timestampToValidate);
        uint256 totalSupply = vestedFXS.totalSupply(timestampToValidate);

        assertEq(totalSupply, votingPowerBob + votingPowerAlice);
    }

    function test_MultiLockOperation() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, unlockTimestamp);

        hoax(alice);
        token.approve(address(vestedFXS), 100e18);
        hoax(alice);
        vestedFXS.createLock(alice, 40e18, unlockTimestamp);

        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);

        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);

        hoax(alice);
        vestedFXS.createLock(alice, 10e18, unlockTimestamp);

        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);

        uint256 ts = block.timestamp;

        assertEq(token.balanceOf(address(vestedFXS)), 100e18);
        assertLe(vestedFXS.balanceOfOneLockAtTime(alice, 0, ts), vestedFXS.balanceOfOneLockAtTime(bob, 0, ts));
        assertLe(vestedFXS.balanceOfOneLockAtTime(alice, 1, ts), vestedFXS.balanceOfOneLockAtTime(bob, 0, ts));
        assertGt(vestedFXS.balanceOfOneLockAtTime(alice, 0, ts) + vestedFXS.balanceOfOneLockAtTime(alice, 1, ts), vestedFXS.balanceOfOneLockAtTime(bob, 0, ts));
        assertEq(vestedFXS.numLocks(bob), 1);
        assertEq(vestedFXS.numLocks(alice), 2);

        vm.roll(block.number + 100);
        skip(uint256(uint128(MAXTIME)) / 2);
        vestedFXS.checkpoint();

        unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);

        hoax(alice);
        vestedFXS.increaseUnlockTime(unlockTimestamp, 1);

        vm.roll(block.number + 10);
        skip(uint256(uint128(MAXTIME)) / 2);
        vestedFXS.checkpoint();
        ts = block.timestamp;

        vm.expectRevert(VestedFXS.LockExpired.selector);
        hoax(bob);
        vestedFXS.increaseUnlockTime(unlockTimestamp, 0);

        vm.expectRevert(VestedFXS.LockCanOnlyBeUpToFourYears.selector);
        hoax(alice);
        vestedFXS.increaseUnlockTime(uint128(block.timestamp) + uint128(MAXTIME) * 2, 1);

        uint256 initialLockId = vestedFXS.indicesToIds(alice, 1);
        (int128 initialLock,) = vestedFXS.locked(alice, initialLockId);

        hoax(alice);
        vestedFXS.withdraw(0);

        uint256 migratedLockId = vestedFXS.indicesToIds(alice, 0);
        (int128 migratedLock,) = vestedFXS.locked(alice, migratedLockId);

        assertEq(initialLock, migratedLock);
        assertEq(vestedFXS.numLocks(alice), 1);

        uint256 increasedLockId = vestedFXS.indicesToIds(alice, 0);
        hoax(alice);
        vestedFXS.increaseAmount(10e18, 0);

        vm.roll(block.number + 10);
        skip(uint256(uint128(WEEK)) * 2);
        vestedFXS.checkpoint();
        ts = block.timestamp;

        (int128 increasedLock,) = vestedFXS.lockedById(alice, increasedLockId);

        assertGt(increasedLock, migratedLock);
    }

    function test_GlobalStateUpdates() public {
        vestedFXSSetup();

        uint256 startTimestamp = 100e18;
        skip(startTimestamp - block.timestamp);
        assertEq(block.timestamp, startTimestamp);

        uint256 amount = 50e18;

        token.mint(address(this), amount * 10);

        token.approve(address(vestedFXS), amount * 5);

        uint128 unlockTimestamp = ((uint128(block.timestamp) + uint128(MAXTIME)) / uint128(WEEK)) * uint128(WEEK);
        vestedFXS.createLock(address(this), 40e18, unlockTimestamp);
        vm.roll(42);
        vestedFXS.increaseAmount(10e18, 0);

        uint256 lockId = vestedFXS.indicesToIds(address(this), 0);
        (int128 retrievedAmount, uint256 retrievedEnd) = vestedFXS.locked(address(this), lockId);
        assertEq(retrievedAmount, int128(uint128(amount)));
        assertEq(retrievedEnd, unlockTimestamp);
        assertEq(vestedFXS.userPointEpoch(address(this), lockId), 2);

        assertEq(vestedFXS.epoch(), 2);
        (int128 retrievedBias, int128 retrievedSlope, uint256 retrievedTs, uint256 retrievedBlk, uint256 retrievedFxsAmt) = vestedFXS.userPointHistory(address(this), lockId, 2);
        assertEq(retrievedBias, 199_341_704_718_395_446_400); // 50e18 + slopeFromBelow * (unlockTimestamp - startTimestamp)
        assertEq(retrievedSlope, 1_189_117_199_391); // 50e18 * VOTE_WEIGHT_MULTIPLIER / MAXTIME
        assertEq(retrievedTs, 100e18);
        assertEq(retrievedBlk, 42);
        assertEq(retrievedFxsAmt, 50e18);

        (retrievedBias, retrievedSlope, retrievedTs, retrievedBlk, retrievedFxsAmt) = vestedFXS.pointHistory(2);
        assertEq(retrievedBias, 199_341_704_718_395_446_400); // 50e18 + slopeFromBelow * (unlockTimestamp - startTimestamp)
        assertEq(retrievedSlope, 1_189_117_199_391); // 50e18 * VOTE_WEIGHT_MULTIPLIER / MAXTIME
        assertEq(retrievedTs, 100e18);
        assertEq(retrievedBlk, 42);
        assertEq(retrievedFxsAmt, 50e18);

        assertEq(vestedFXS.totalFXSSupply(), amount);

        skip(7 * 86_400);
        vm.roll(50);

        vestedFXS.createLock(address(this), amount, unlockTimestamp);
        assertEq(vestedFXS.epoch(), 4);
        lockId = vestedFXS.indicesToIds(address(this), 1);
        (retrievedBias, retrievedSlope, retrievedTs, retrievedBlk, retrievedFxsAmt) = vestedFXS.userPointHistory(address(this), lockId, 1);
        assertEq(retrievedBias, 198_622_526_636_203_769_600); // 50e18 + slopeFromBelow * (unlockTimestamp - startTimestamp)
        assertEq(retrievedSlope, 1_189_117_199_391); // 50e18 * VOTE_WEIGHT_MULTIPLIER / MAXTIME
        assertEq(retrievedTs, 100e18 + (7 * 86_400));
        assertEq(retrievedBlk, 50);
        assertEq(retrievedFxsAmt, 50e18);

        (retrievedBias, retrievedSlope, retrievedTs, retrievedBlk, retrievedFxsAmt) = vestedFXS.pointHistory(4);
        assertEq(retrievedBias, 397_245_053_272_407_539_200);
        assertEq(retrievedSlope, 2_378_234_398_782);
        assertEq(retrievedTs, 100e18 + (7 * 86_400));
        assertEq(retrievedBlk, 50);
        assertEq(retrievedFxsAmt, 100e18);

        assertEq(vestedFXS.totalFXSSupply(), amount * 2);
    }

    function testZach_CreateLockTsBounds() public {
        vestedFXSSetup();
        vm.warp(block.timestamp + 100);

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        (, uint128 latest) = vestedFXS.getCreateLockTsBounds();
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, latest);

        uint256 lockId = vestedFXS.indicesToIds(bob, 0);
        (, uint256 end) = vestedFXS.locked(bob, lockId);
        console.log("end: ", end);
        console.log("latest: ", latest);
        assertEq(end, latest);
        // assertLt(end, latest);
    }

    function testZach_NoPastBalance() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 60e18);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, uint128(block.timestamp + 1 weeks));

        vestedFXS.balanceOfAllLocksAtTime(bob, block.timestamp - 1);
    }

    function testZach_TotalSupplyBug() public {
        vestedFXSSetup();
        vestedFXS.checkpoint();
        uint256 targetTs = block.timestamp;

        (uint128 earliest,) = vestedFXS.getCreateLockTsBounds();
        vm.warp(earliest + 21 days - 1);

        uint256 supply = vestedFXS.totalSupply(targetTs);
        assertEq(supply, 0);

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, uint128(block.timestamp + 1));

        uint256 newSupply = vestedFXS.totalSupply(targetTs);
        // TODO: Needs a fix -- fixed
        assertEq(newSupply, 0); // After fix, this should be used
            // assertEq(newSupply, 52_294_436_120_623_716_839);
    }

    function test_balanceFunctionsReturningFxsAmountWhenEmergencyUnlockIsActive() public {
        vestedFXSSetup();

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        hoax(alice);
        token.approve(address(vestedFXS), 50e18);

        hoax(bob);
        vestedFXS.createLock(bob, 20e18, uint128(block.timestamp + 10 weeks));
        hoax(bob);
        vestedFXS.createLock(bob, 22e18, uint128(block.timestamp + 20 weeks));
        hoax(alice);
        vestedFXS.createLock(alice, 16e18, uint128(block.timestamp + 30 weeks));

        vestedFXS.activateEmergencyUnlock();

        assertEq(vestedFXS.balanceOf(bob), 42e18);
        assertEq(vestedFXS.balanceOf(alice), 16e18);
        assertEq(vestedFXS.balanceOfAt(bob, block.number - 10), 42e18);
        assertEq(vestedFXS.balanceOfAt(bob, block.number + 10), 42e18);
        assertEq(vestedFXS.balanceOfAt(alice, block.number - 10), 16e18);
        assertEq(vestedFXS.balanceOfAt(alice, block.number + 10), 16e18);
        assertEq(vestedFXS.balanceOfAllLocksAtBlock(bob, block.number - 10), 42e18);
        assertEq(vestedFXS.balanceOfAllLocksAtBlock(bob, block.number + 10), 42e18);
        assertEq(vestedFXS.balanceOfAllLocksAtBlock(alice, block.number - 10), 16e18);
        assertEq(vestedFXS.balanceOfAllLocksAtBlock(alice, block.number + 10), 16e18);
        assertEq(vestedFXS.balanceOfAllLocksAtTime(bob, block.timestamp + 4 weeks), 42e18);
        assertEq(vestedFXS.balanceOfAllLocksAtTime(bob, block.timestamp - 4 weeks), 42e18);
        assertEq(vestedFXS.balanceOfAllLocksAtTime(alice, block.timestamp + 4 weeks), 16e18);
        assertEq(vestedFXS.balanceOfAllLocksAtTime(alice, block.timestamp - 4 weeks), 16e18);
        assertEq(vestedFXS.balanceOfOneLockAtBlock(bob, 0, block.number - 10), 20e18);
        assertEq(vestedFXS.balanceOfOneLockAtBlock(bob, 0, block.number + 10), 20e18);
        assertEq(vestedFXS.balanceOfOneLockAtBlock(bob, 1, block.number - 10), 22e18);
        assertEq(vestedFXS.balanceOfOneLockAtBlock(bob, 1, block.number + 10), 22e18);
        assertEq(vestedFXS.balanceOfOneLockAtBlock(alice, 0, block.number - 10), 16e18);
        assertEq(vestedFXS.balanceOfOneLockAtBlock(alice, 0, block.number + 10), 16e18);
        assertEq(vestedFXS.balanceOfOneLockAtTime(bob, 0, block.timestamp + 4 weeks), 20e18);
        assertEq(vestedFXS.balanceOfOneLockAtTime(bob, 0, block.timestamp - 4 weeks), 20e18);
        assertEq(vestedFXS.balanceOfOneLockAtTime(bob, 1, block.timestamp + 4 weeks), 22e18);
        assertEq(vestedFXS.balanceOfOneLockAtTime(bob, 1, block.timestamp - 4 weeks), 22e18);
        assertEq(vestedFXS.balanceOfOneLockAtTime(alice, 0, block.timestamp + 4 weeks), 16e18);
        assertEq(vestedFXS.balanceOfOneLockAtTime(alice, 0, block.timestamp - 4 weeks), 16e18);

        assertEq(vestedFXS.lockedEnd(bob, 0), block.timestamp);
        assertEq(vestedFXS.lockedEnd(bob, 1), block.timestamp);
        assertEq(vestedFXS.lockedEnd(alice, 0), block.timestamp);

        assertEq(vestedFXS.totalSupply(), 58e18);
        assertEq(vestedFXS.totalSupply(block.timestamp + 4 weeks), 58e18);
        assertEq(vestedFXS.totalSupply(block.timestamp - 4 weeks), 58e18);

        assertEq(vestedFXS.totalSupplyAt(block.number), 58e18);
        assertEq(vestedFXS.totalSupplyAt(block.number - 10), 58e18);
    }

    function test_supplyAtReverts() public {
        vestedFXSSetup();

        IveFXSStructs.Point memory point = IveFXSStructs.Point(0, 0, 42, 0, 0);

        vm.expectRevert(VestedFXS.InvalidTimestamp.selector);
        vestedFXS.supplyAt(point, 16);

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, uint128(block.timestamp + uint128(MAXTIME)));

        vestedFXS.activateEmergencyUnlock();

        uint256 retrievedCurrentSupply = vestedFXS.supplyAt(point, block.timestamp);
        uint256 retrievedPastSupply = vestedFXS.supplyAt(point, block.timestamp - 1 weeks);
        uint256 retrievedFutureSupply = vestedFXS.supplyAt(point, block.timestamp + 1 weeks);

        assertEq(retrievedCurrentSupply, 50e18);
        assertEq(retrievedPastSupply, 50e18);
        assertEq(retrievedFutureSupply, 50e18);
    }
}
