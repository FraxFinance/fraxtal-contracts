// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "frax-std/FraxTest.sol";
import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";

contract Unit_Test_VestedFXS_Combi is BaseTestVeFXS {
    uint256 startBlockNumber;
    uint256 startTimestamp;

    function setUp() public {
        super.defaultSetup();

        token.mint(alice, 100e18);
        token.mint(bob, 100e18);
        token.mint(claire, 100e18);
        token.mint(dave, 100e18);
        token.mint(eric, 100e18);
        token.mint(frank, 100e18);

        startBlockNumber = block.number;
        startTimestamp = block.timestamp;
    }

    function test_veFXS_Combi_Withdraw_Out_Of_Range() public {
        console.log("<<<Testing out of range>>>");
        lock(dave, 1e18, unlockTimestamp(7));
        skipWithBlock(uint128(3 * DAY));
        checkBalancesAtBlock(uint256(block.timestamp));
        skipWithBlock(uint128(4 * DAY));
        withdraw(dave, 0);
    }

    function test_veFXS_Combi_Big() public {
        console.log("<<<Doing first set of locks>>>");
        console.log("<<<Alice...>>>");
        lock(alice, 1e18, unlockTimestamp(7));
        console.log("<<<Alice's 1st lock done>>>");
        lock(alice, 1e18, unlockTimestamp(2 * 365));
        console.log("<<<Alice's 2nd lock done>>>");
        console.log("<<<Bob...>>>");
        lock(bob, 1e18, unlockTimestamp(4 * 365));
        console.log("<<<Claire...>>>");
        lock(claire, 1e18, unlockTimestamp(1 * 365));
        lock(claire, 1e18, unlockTimestamp(2 * 365));
        skipWithBlock(uint128(7 * DAY));
        console.log("<<<First Alice withdrawal>>>");
        withdraw(alice, 0);
        lock(alice, 1e18, unlockTimestamp(7));
        skipWithBlock(uint128(7 * DAY));
        console.log("<<<Second Alice withdrawal>>>");
        withdraw(alice, 1);
        console.log("<<<Doing second set of locks>>>");
        console.log("<<<Dave...>>>");
        lock(dave, 1e18, unlockTimestamp(35));
        lock(dave, 1e18, unlockTimestamp(28));
        lock(dave, 1e18, unlockTimestamp(21));
        lock(dave, 1e18, unlockTimestamp(14));
        lock(dave, 1e18, unlockTimestamp(7));
        console.log("<<<Eric...>>>");
        lock(eric, 1e18, unlockTimestamp(7));
        lock(eric, 1e18, unlockTimestamp(14));
        lock(eric, 1e18, unlockTimestamp(21));
        lock(eric, 1e18, unlockTimestamp(28));
        lock(eric, 1e18, unlockTimestamp(35));
        console.log("<<<Frank...>>>");
        lock(frank, 1e18, unlockTimestamp(21));
        lock(frank, 1e18, unlockTimestamp(14));
        lock(frank, 1e18, unlockTimestamp(7));
        lock(frank, 1e18, unlockTimestamp(35));
        lock(frank, 1e18, unlockTimestamp(28));
        console.log("<<<Starting withdrawals>>>");
        skipWithBlock(uint128(7 * DAY));
        withdraw(dave, 4);
        withdraw(eric, 0);
        withdraw(frank, 2);
        skipWithBlock(uint128(7 * DAY));
        withdraw(dave, 3);
        withdraw(eric, 1);
        withdraw(frank, 1);
        skipWithBlock(uint128(7 * DAY));
        withdraw(dave, 2);
        withdraw(eric, 2);
        withdraw(frank, 0);
        skipWithBlock(uint128(7 * DAY));
        withdraw(dave, 1);
        withdraw(eric, 1);
        withdraw(frank, 0);
        skipWithBlock(uint128(7 * DAY));
        withdraw(dave, 0);
        withdraw(eric, 0);
        withdraw(frank, 0);
        skipWithBlock(uint128(365 * DAY));
        withdraw(claire, 0);
        skipWithBlock(uint128(365 * DAY));
        withdraw(alice, 0);
        withdraw(claire, 0);
        skipWithBlock(uint128(2 * 365 * DAY));
        withdraw(bob, 0);
        console.log("<<<Withdrawals done>>>");
        assertEq(vestedFXS.totalSupply(0), 0);
    }

    function skipWithBlock(uint256 time) public {
        skip(time);
        vm.roll(startBlockNumber + block.timestamp - startTimestamp);
    }

    function unlockTimestamp(uint256 noDays) public returns (uint128) {
        return ((uint128(block.timestamp) + uint128(noDays * DAY)) / uint128(WEEK)) * uint128(WEEK);
    }

    function lock(address user, uint256 amount, uint128 timestamp) public {
        console.log("<<<Checking pre-lock invariants>>>");
        checkInvariants();
        hoax(user);
        token.approve(address(vestedFXS), amount);
        hoax(user);
        console.log("<<<Creating the lock>>>");
        vestedFXS.createLock(user, amount, timestamp);
        console.log("<<<Checking post-lock invariants>>>");
        checkInvariants();
    }

    function withdraw(address user, uint128 index) public {
        checkInvariants();
        hoax(user);
        vestedFXS.withdraw(index);
        checkInvariants();
    }

    function checkInvariants() public {
        checkBalances();
        checkCrudeBalances();
        checkBalancesAtFutureTime(uint256(block.timestamp + 1 * DAY));
        // checkBalancesAtBlock(uint256(block.timestamp - 3 * DAY));
        checkBalancesAtBlock(uint256(block.timestamp));
        checkFXS();
    }

    function checkFXS() public {
        console.log("<<<checkFXS...>>>");
        uint256 sum = fxsLocked(alice);
        sum += fxsLocked(bob);
        sum += fxsLocked(claire);
        sum += fxsLocked(dave);
        sum += fxsLocked(eric);
        sum += fxsLocked(frank);
        assertEq(sum, vestedFXS.supply(), "checkFXS() failed (vestedFXS.supply())");
        assertEq(sum, token.balanceOf(address(vestedFXS)), "checkFXS() failed (token.balanceOf(address(vestedFXS))");
    }

    function checkBalancesAtBlock(uint256 timestamp) public {
        console.log("<<<checkBalancesAtBlock...>>>");
        uint256 blockNo = startBlockNumber + timestamp - startTimestamp;
        Point memory point;
        (point.bias, point.slope, point.ts, point.blk, point.fxsAmt) = vestedFXS.pointHistory(1);
        uint256 totalSupply = vestedFXS.totalSupply(timestamp);
        uint256 sum = checkBalanceOfAtBlock(alice, blockNo);
        sum += checkBalanceOfAtBlock(bob, blockNo);
        sum += checkBalanceOfAtBlock(claire, blockNo);
        sum += checkBalanceOfAtBlock(dave, blockNo);
        sum += checkBalanceOfAtBlock(eric, blockNo);
        sum += checkBalanceOfAtBlock(frank, blockNo);
        //console.log("totalSupply:%d",totalSupply);
        //console.log("sum        :%d",sum);
        if (totalSupply < sum) assertEq(sum, totalSupply, "checkBalancesAtBlock() failed");
    }

    function checkBalancesAtFutureTime(uint256 timestamp) public {
        console.log("<<<checkBalancesAtFutureTime...>>>");
        uint256 totalSupply = vestedFXS.totalSupply(timestamp);
        uint256 sum = checkBalanceOfAtTime(alice, timestamp);
        sum += checkBalanceOfAtTime(bob, timestamp);
        sum += checkBalanceOfAtTime(claire, timestamp);
        sum += checkBalanceOfAtTime(dave, timestamp);
        sum += checkBalanceOfAtTime(eric, timestamp);
        sum += checkBalanceOfAtTime(frank, timestamp);
        assertEq(sum, totalSupply, "checkBalancesAtFutureTime() failed");
    }

    function checkBalances() public {
        console.log("<<<checkBalances...>>>");
        uint256 totalSupply = vestedFXS.totalSupply(0);
        uint256 sum = checkBalanceOf(alice);
        sum += checkBalanceOf(bob);
        sum += checkBalanceOf(claire);
        sum += checkBalanceOf(dave);
        sum += checkBalanceOf(eric);
        sum += checkBalanceOf(frank);
        assertEq(sum, totalSupply, "checkBalances() failed");
    }

    function checkCrudeBalances() public {
        console.log("<<<checkCrudeBalances...>>>");
        uint256 totalSupply = vestedFXS.totalSupply();
        uint256 sum = checkCrudeBalanceOf(alice);
        sum += checkCrudeBalanceOf(bob);
        sum += checkCrudeBalanceOf(claire);
        sum += checkCrudeBalanceOf(dave);
        sum += checkCrudeBalanceOf(eric);
        sum += checkCrudeBalanceOf(frank);
        assertApproxEqRel(sum, totalSupply, 0.01e18, "checkCrudeBalances() failed");
    }

    function checkBalanceOfAtBlock(address user, uint256 blockNo) public returns (uint256 result) {
        uint256 _numLocks = vestedFXS.numLocks(user);
        for (uint128 i = 0; i < _numLocks; ++i) {
            uint256 balance = vestedFXS.balanceOfOneLockAtBlock(user, i, uint128(blockNo));
            result += balance;
        }
    }

    function checkBalanceOfAtTime(address user, uint256 timestamp) public returns (uint256 result) {
        uint256 _numLocks = vestedFXS.numLocks(user);
        for (uint128 i = 0; i < _numLocks; ++i) {
            uint256 balance = vestedFXS.balanceOfOneLockAtTime(user, i, timestamp);
            result += balance;
        }
    }

    function checkBalanceOf(address user) public returns (uint256 result) {
        uint256 _numLocks = vestedFXS.numLocks(user);
        for (uint128 i = 0; i < _numLocks; ++i) {
            uint256 balance = vestedFXS.balanceOfOneLockAtTime(user, i, 0);
            LockedBalance memory lockedBalance;
            (lockedBalance.amount, lockedBalance.end) = vestedFXS.lockedByIndex(user, i);
            int128 balanceViaLockerBalance = lockedBalance.amount;
            if (lockedBalance.end > block.timestamp) balanceViaLockerBalance = lockedBalance.amount + ((lockedBalance.amount * 3 * (int128(lockedBalance.end) - int128(int256(block.timestamp)))) / MAXTIME);

            string memory errorMsg = string(abi.encodePacked("checkBalanceOf() failed for ", vm.getLabel(user)));
            assertApproxEqAbs(balance, uint128(balanceViaLockerBalance), balance / 1_000_000_000, errorMsg);
            result += balance;
        }
    }

    function checkCrudeBalanceOf(address user) public returns (uint256 result) {
        uint256 _actualBalance = vestedFXS.balanceOf(user);
        uint256 _crudeBalance = vestedFXSUtils.getCrudeExpectedVeFXSUser(user);
        string memory errorMsg = string(abi.encodePacked("checkCrudeBalanceOf() failed for ", vm.getLabel(user)));
        assertApproxEqRel(_actualBalance, _crudeBalance, 0.01e18, errorMsg);
        result += _crudeBalance;
    }

    function fxsLocked(address user) public returns (uint256 result) {
        int128 sum;
        for (uint128 i = 0; i < vestedFXS.numLocks(user); ++i) {
            (int128 amount,) = vestedFXS.lockedByIndex(user, i);
            sum += amount;
        }
        return uint128(sum);
    }
}
