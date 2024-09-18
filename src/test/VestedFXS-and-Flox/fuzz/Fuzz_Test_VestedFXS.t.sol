// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "frax-std/FraxTest.sol";
import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";

contract Fuzz_Test_VestedFXS is BaseTestVeFXS {
    function setUp() public {
        defaultSetup();

        // Mint FXS to the test users
        token.mint(alice, 100e18);
        token.mint(bob, 100e18);
    }

    function testFuzz_CreateLock(address user, address floxContributor, uint256 amount, uint128 unlockTimestamp, bool useFloxContributor) public {
        vm.assume(user != address(0));
        vm.assume(floxContributor != address(0));
        amount = bound(amount, 1000 gwei, 10_000_000e18);
        uint128 lowerBound = uint128(block.timestamp) + uint128(WEEK);
        uint128 upperBound = uint128(block.timestamp) + uint128(MAXTIME);
        unlockTimestamp = uint128(bound(unlockTimestamp, lowerBound, upperBound));

        uint256 unlockTimestamp_ = (uint256(unlockTimestamp) / uint256(uint128(WEEK))) * uint256(uint128(WEEK));

        if (useFloxContributor) {
            token.mint(floxContributor, amount);
            hoax(floxContributor);
            token.approve(address(vestedFXS), amount);
        } else {
            token.mint(user, amount);
            hoax(user);
            token.approve(address(vestedFXS), amount);
        }

        uint128 lockIndex = vestedFXS.numLocks(user);
        uint256 initialBalance = token.balanceOf(address(vestedFXS));

        if (useFloxContributor) {
            vestedFXS.setFloxContributor(floxContributor, true);
            hoax(floxContributor);
        } else {
            hoax(user);
        }
        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(user, useFloxContributor ? floxContributor : user, unlockTimestamp_, amount, CREATE_LOCK_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(initialBalance, initialBalance + amount);
        vestedFXS.createLock(user, amount, unlockTimestamp);

        (int128 retrievedAmount, uint256 retrievedEnd) = vestedFXS.lockedByIndex(user, lockIndex);

        assertEq(retrievedAmount, int128(uint128(amount)));
        assertEq(retrievedEnd, unlockTimestamp_);
    }

    function testFuzz_DepositFor(address user, address depositor, uint256 initialAmount, uint128 unlockTimestamp, uint256 increaseValue) public {
        vm.assume(user != address(0));
        vm.assume(depositor != address(0));
        initialAmount = bound(initialAmount, 1000 gwei, 10_000_000e18);
        increaseValue = bound(increaseValue, 1000 gwei, 10_000_000e18);
        uint128 lowerBound = uint128(block.timestamp) + uint128(WEEK);
        uint128 upperBound = uint128(block.timestamp) + uint128(MAXTIME);
        unlockTimestamp = uint128(bound(unlockTimestamp, lowerBound, upperBound));

        uint256 unlockTimestamp_ = (uint256(unlockTimestamp) / uint256(uint128(WEEK))) * uint256(uint128(WEEK));

        uint256 initialBalance = token.balanceOf(address(vestedFXS));
        uint128 lockIndex = vestedFXS.numLocks(user);

        token.mint(user, initialAmount);
        hoax(user);
        token.approve(address(vestedFXS), initialAmount);
        hoax(user);
        vestedFXS.createLock(user, initialAmount, unlockTimestamp);

        token.mint(depositor, increaseValue);
        hoax(depositor);
        token.approve(address(vestedFXS), increaseValue);

        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(user, depositor, unlockTimestamp_, increaseValue, DEPOSIT_FOR_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(initialBalance + initialAmount, initialBalance + initialAmount + increaseValue);

        hoax(depositor);
        vestedFXS.depositFor(user, increaseValue, lockIndex);

        uint256 finalBalance = token.balanceOf(address(vestedFXS));

        assertEq(finalBalance, initialBalance + initialAmount + increaseValue);

        VestedFXS.LockedBalance memory retrievedLock;
        (retrievedLock.amount, retrievedLock.end) = vestedFXS.lockedByIndex(user, lockIndex);

        assertEq(retrievedLock.amount, int128(uint128(initialAmount + increaseValue)));
        assertEq(retrievedLock.end, unlockTimestamp_);
    }

    function testFuzz_IncreaseAmount(address user, uint256 initialAmount, uint256[] memory increaseValues, uint128 unlockTimestamp) public {
        vm.assume(user != address(0));
        initialAmount = bound(initialAmount, 1000 gwei, 10_000_000e18);
        for (uint256 i; i < increaseValues.length;) {
            increaseValues[i] = bound(increaseValues[i], 1000 gwei, 10_000_000e18);

            unchecked {
                ++i;
            }
        }
        uint128 lowerBound = uint128(block.timestamp) + uint128(WEEK);
        uint128 upperBound = uint128(block.timestamp) + uint128(MAXTIME);
        unlockTimestamp = uint128(bound(unlockTimestamp, lowerBound, upperBound));

        uint256 unlockTimestamp_ = (uint256(unlockTimestamp) / uint256(uint128(WEEK))) * uint256(uint128(WEEK));

        uint128 lockIndex = vestedFXS.numLocks(user);

        token.mint(user, initialAmount);
        hoax(user);
        token.approve(address(vestedFXS), initialAmount);
        hoax(user);
        vestedFXS.createLock(user, initialAmount, unlockTimestamp);

        uint256 currentBalance = token.balanceOf(address(vestedFXS));

        for (uint256 i; i < increaseValues.length;) {
            token.mint(user, increaseValues[i]);
            hoax(user);
            token.approve(address(vestedFXS), increaseValues[i]);

            vm.expectEmit(true, true, true, true, address(vestedFXS));
            emit Deposit(user, user, unlockTimestamp_, increaseValues[i], INCREASE_LOCK_AMOUNT, block.timestamp);
            vm.expectEmit(false, false, false, true, address(vestedFXS));
            emit Supply(currentBalance, currentBalance + increaseValues[i]);

            hoax(user);
            vestedFXS.increaseAmount(increaseValues[i], lockIndex);

            uint256 finalBalance = token.balanceOf(address(vestedFXS));

            assertEq(finalBalance, currentBalance + increaseValues[i]);

            VestedFXS.LockedBalance memory retrievedLock;
            (retrievedLock.amount, retrievedLock.end) = vestedFXS.lockedByIndex(user, lockIndex);

            assertEq(retrievedLock.amount, int128(uint128(currentBalance + increaseValues[i])));
            assertEq(retrievedLock.end, unlockTimestamp_);

            currentBalance = finalBalance;

            unchecked {
                ++i;
            }
        }
    }

    // TODO: Fix this test. It appears to gas out at times
    // function testFuzz_IncreaseUnlockTime(address user, uint256 amount, uint128[] memory increaseTimes) public {
    //     vm.assume(user != address(0));
    //     amount = bound(amount, 1000 gwei, 10_000_000e18);
    //     vm.assume(increaseTimes.length > 0);
    //     for (uint256 i; i < increaseTimes.length;) {
    //         increaseTimes[i] = (uint128(bound(increaseTimes[i], uint128(WEEK), uint128(MAXTIME) - uint128(WEEK))) / uint128(WEEK)) * uint128(WEEK);

    //         unchecked {
    //             ++i;
    //         }
    //     }
    //     uint128 unlockTimestamp = uint128(block.timestamp) + uint128(WEEK);

    //     uint128 currentUnlockTimestamp = (unlockTimestamp / uint128(WEEK)) * uint128(WEEK);

    //     uint128 lockIndex = vestedFXS.numLocks(user);

    //     token.mint(user, amount);
    //     hoax(user);
    //     token.approve(address(vestedFXS), amount);
    //     hoax(user);
    //     vestedFXS.createLock(user, amount, unlockTimestamp);

    //     LockedBalance memory retrievedBalance;

    //     // Checkpoint globally beforehand to split up gas
    //     vestedFXS.checkpoint();

    //     for (uint256 i; i < increaseTimes.length;) {
    //         vm.expectEmit(true, true, true, true, address(vestedFXS));
    //         emit Deposit(user, user, currentUnlockTimestamp + increaseTimes[i], 0, INCREASE_UNLOCK_TIME, block.timestamp);
    //         vm.expectEmit(false, false, false, true, address(vestedFXS));
    //         emit Supply(amount, amount);
    //         hoax(user);
    //         vestedFXS.increaseUnlockTime(currentUnlockTimestamp + increaseTimes[i], lockIndex);

    //         (retrievedBalance.amount, retrievedBalance.end) = vestedFXS.lockedByIndex(user, lockIndex);
    //         assertEq(uint256(uint128(retrievedBalance.amount)), amount);
    //         assertEq(retrievedBalance.end, currentUnlockTimestamp + increaseTimes[i]);

    //         currentUnlockTimestamp += increaseTimes[i];

    //         vm.roll(block.number + 10);
    //         skip(increaseTimes[i]);

    //         unchecked {
    //             ++i;
    //         }
    //     }
    // }

    function testFuzz_Withdraw(address user, address floxContributor, uint256 amount, uint128 unlockTimestamp, bool useFloxContributor) public {
        vm.assume(user != address(0));
        vm.assume(floxContributor != address(0));
        amount = bound(amount, 1000 gwei, 10_000_000e18);
        uint128 lowerBound = uint128(block.timestamp) + (uint128(WEEK));
        uint128 upperBound = uint128(block.timestamp) + uint128(MAXTIME);
        unlockTimestamp = uint128(bound(unlockTimestamp, lowerBound, upperBound));

        uint128 lockIndex = vestedFXS.numLocks(user);

        if (useFloxContributor) {
            vestedFXS.setFloxContributor(floxContributor, true);
            token.mint(floxContributor, amount);
            hoax(floxContributor);
            token.approve(address(vestedFXS), amount);
            hoax(floxContributor);
        } else {
            token.mint(user, amount);
            hoax(user);
            token.approve(address(vestedFXS), amount);
            hoax(user);
        }
        vestedFXS.createLock(user, amount, unlockTimestamp);

        uint256 initialUserBalance = token.balanceOf(user);
        uint256 initialContractBalance = token.balanceOf(address(vestedFXS));

        vm.roll(block.number + 10);
        skip(uint128(MAXTIME));

        vm.expectEmit(true, false, false, true, address(vestedFXS));
        emit Withdraw(user, user, amount, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(amount, initialContractBalance - amount);
        hoax(user);
        vestedFXS.withdraw(lockIndex);

        uint256 finalUserBalance = token.balanceOf(user);
        uint256 finalContractBalance = token.balanceOf(address(vestedFXS));

        assertEq(finalUserBalance, initialUserBalance + amount);
        assertEq(finalContractBalance, initialContractBalance - amount);
    }

    function testFuzz_RandomOperation(address user, address floxContributor, uint256 amount, uint128 unlockTsU128, uint128 increaseTime, uint256 increaseValue, bool useFloxContributor, bool useIncreaseUnlockTime, bool useIncreaseValue, bool withdraw) public {
        vm.assume(user != address(0));
        vm.assume(floxContributor != address(0));
        amount = bound(amount, 1000 gwei, 10_000_000e18);
        uint128 lowerBound = uint128(block.timestamp) + (uint128(WEEK) * 6);
        uint128 upperBound = uint128(block.timestamp) + uint128(MAXTIME) - (uint128(WEEK) * 4);
        unlockTsU128 = uint128(bound(unlockTsU128, lowerBound, upperBound));
        increaseTime = (uint128(bound(increaseTime, uint128(WEEK), upperBound - unlockTsU128 + (uint128(WEEK) * 2))) / uint128(WEEK)) * uint128(WEEK);
        increaseValue = bound(increaseValue, 1000 gwei, 10_000_000e18);
        uint256 unlockTsTruncU256 = (uint256(unlockTsU128) / uint256(uint128(WEEK))) * uint256(uint128(WEEK));

        console.log("---------------------- BOUND VARIABLES ----------------------");
        console.log("amount: %s", amount);
        console.log("unlockTsU128: %s", unlockTsU128);
        console.log("increaseTime: %s", increaseTime);
        console.log("increaseValue: %s", increaseValue);
        console.log("unlockTsTruncU256: %s", unlockTsTruncU256);
        console.log("useFloxContributor: %s", useFloxContributor);
        console.log("useIncreaseUnlockTime: %s", useIncreaseUnlockTime);
        console.log("useIncreaseValue: %s", useIncreaseValue);
        console.log("withdraw: %s", withdraw);

        console.log("---------------------- mint ----------------------");
        if (useFloxContributor) {
            console.log("   -- Using floxContributor");
            token.mint(floxContributor, amount);
            hoax(floxContributor);
            token.approve(address(vestedFXS), amount);
        } else {
            console.log("   -- Using user");
            token.mint(user, amount);
            hoax(user);
            token.approve(address(vestedFXS), amount);
        }

        uint256 initialBalance = token.balanceOf(address(vestedFXS));

        console.log("---------------------- createLock ----------------------");
        if (useFloxContributor) {
            console.log("   -- Using floxContributor");
            vestedFXS.setFloxContributor(floxContributor, true);
            hoax(floxContributor);
        } else {
            console.log("   -- Using user");
            hoax(user);
        }
        vm.expectEmit(true, true, true, true, address(vestedFXS));
        emit Deposit(user, useFloxContributor ? floxContributor : user, unlockTsTruncU256, amount, CREATE_LOCK_TYPE, block.timestamp);
        vm.expectEmit(false, false, false, true, address(vestedFXS));
        emit Supply(initialBalance, initialBalance + amount);
        vestedFXS.createLock(user, amount, unlockTsU128);

        if (useIncreaseUnlockTime) {
            console.log("---------------------- increaseUnlockTime ----------------------");
            console.log("   -- checkpoint");
            vm.roll(block.number + 10);
            skip(uint128(WEEK) * 2);
            vestedFXS.checkpoint();

            console.log("   -- increaseUnlockTime");
            vm.expectEmit(true, true, true, true, address(vestedFXS));
            emit Deposit(user, user, unlockTsTruncU256 + increaseTime, 0, INCREASE_UNLOCK_TIME, uint256(block.timestamp));
            vm.expectEmit(false, false, false, true, address(vestedFXS));
            emit Supply(initialBalance + amount, initialBalance + amount);
            hoax(user);
            vestedFXS.increaseUnlockTime(unlockTsU128 + increaseTime, 0);
        } else {
            console.log("---------------------- SKIPPING increaseUnlockTime ----------------------");
        }

        console.log("---------------------- useIncreaseValue ----------------------");
        if (useIncreaseValue) {
            console.log("   -- checkpoint");
            vm.roll(block.number + 10);
            skip(uint128(WEEK) * 2);
            vestedFXS.checkpoint();

            token.mint(user, increaseValue);
            initialBalance = token.balanceOf(address(vestedFXS));

            hoax(user);
            token.approve(address(vestedFXS), increaseValue);
            if (useIncreaseUnlockTime) {
                console.log("   -- expectEmit WITH useIncreaseUnlockTime precondition");
                vm.expectEmit(true, true, true, true, address(vestedFXS));
                emit Deposit(user, user, unlockTsTruncU256 + increaseTime, increaseValue, INCREASE_LOCK_AMOUNT, block.timestamp);
            } else {
                console.log("   -- expectEmit WITHOUT useIncreaseUnlockTime precondition");
                vm.expectEmit(true, true, true, true, address(vestedFXS));
                emit Deposit(user, user, unlockTsTruncU256, increaseValue, INCREASE_LOCK_AMOUNT, block.timestamp);
            }
            vm.expectEmit(false, false, false, true, address(vestedFXS));
            emit Supply(initialBalance, initialBalance + increaseValue);
            hoax(user);
            vestedFXS.increaseAmount(increaseValue, 0);
        }

        console.log("---------------------- withdraw ----------------------");
        if (withdraw) {
            console.log("   -- checkpoint");
            vm.roll(block.number + 10);
            skip(uint128(MAXTIME) + 1);
            vestedFXS.checkpoint();

            initialBalance = token.balanceOf(address(vestedFXS));

            if (useIncreaseValue) {
                console.log("   -- expectEmit [Withdraw] WITH useIncreaseUnlockTime precondition");
                vm.expectEmit(true, false, false, true, address(vestedFXS));
                emit Withdraw(user, user, amount + increaseValue, block.timestamp);
            } else {
                console.log("   -- expectEmit [Withdraw] WITHOUT useIncreaseUnlockTime precondition");
                vm.expectEmit(true, false, false, true, address(vestedFXS));
                emit Withdraw(user, user, amount, block.timestamp);
            }

            if (useIncreaseValue) {
                console.log("   -- expectEmit [Supply] WITH useIncreaseUnlockTime precondition");
                vm.expectEmit(false, false, false, true, address(vestedFXS));
                emit Supply(initialBalance, initialBalance - (amount + increaseValue));
            } else {
                console.log("   -- expectEmit [Supply] WITHOUT useIncreaseUnlockTime precondition");
                vm.expectEmit(false, false, false, true, address(vestedFXS));
                emit Supply(initialBalance, initialBalance - amount);
            }
            hoax(user);
            vestedFXS.withdraw(0);
        }
    }

    function testFuzz_ZachCreateLockTsBounds(uint256 time) public {
        time = bound(time, 0, 4 * 365 * DAY);

        vm.warp(block.timestamp + time);

        hoax(bob);
        token.approve(address(vestedFXS), 50e18);
        (, uint128 latest) = vestedFXS.getCreateLockTsBounds();
        hoax(bob);
        vestedFXS.createLock(bob, 50e18, latest);

        uint256 lockId = vestedFXS.indicesToIds(bob, 0);
        (, uint256 end) = vestedFXS.locked(bob, lockId);
        assertEq(end, latest);
        // assertLt(end, latest);
    }
}
