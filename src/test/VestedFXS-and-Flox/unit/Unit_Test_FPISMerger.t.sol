// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

import { FraxTest } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { FPISMerger } from "src/contracts/VestedFXS-and-Flox/FPISMerger/FPISMerger.sol";
import "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";

// This test is isolated from BaseTestVeFXS.t.sol
contract Unit_Test_FPISMerger is FraxTest {
    IERC20 FXS = IERC20(0xFc00000000000000000000000000000000000002);
    IERC20 FPIS = IERC20(0xfc00000000000000000000000000000000000004);
    FPISMerger merger;

    uint256 public alicePrivateKey;
    address payable public alice;
    uint256 public bobPrivateKey;
    address payable public bob;
    uint256 public clairePrivateKey;
    address payable public claire;
    uint256 public davePrivateKey;
    address payable public dave;

    uint256 startBlockNumber;
    uint256 startTimestamp;

    function setUpFraxtalMainnet() public {
        // Set test users
        alice = payable(vm.addr(0xa1));
        vm.label(alice, "Alice");
        bob = payable(vm.addr(0xb1));
        vm.label(bob, "Bob");
        claire = payable(vm.addr(0xc1));
        vm.label(claire, "Claire");
        dave = payable(vm.addr(0xd1));
        vm.label(dave, "Dave");

        // Switch to Fraxtal
        vm.createSelectFork(vm.envString("FRAXTAL_RPC_URL"), 854_867);

        // Create the merger contract
        merger = new FPISMerger();

        // Note starting block and time
        startBlockNumber = block.number;
        startTimestamp = block.timestamp;
    }

    function test_lock_unlock() public {
        setUpFraxtalMainnet();
        deal(address(FPIS), alice, 10e18);
        hoax(alice);
        FPIS.approve(address(merger), 10e18);
        hoax(alice);
        merger.lock(1e18);

        vm.expectRevert(FPISMerger.NotYetUnlocked.selector);
        merger.unlock(alice);

        hoax(alice);
        vm.expectRevert(FPISMerger.ZeroAmount.selector);
        merger.lock(0);

        skipWithBlock(1 * 365 * 86_400);
        vm.expectRevert(FPISMerger.NotYetUnlocked.selector);
        merger.unlock(alice);

        hoax(alice);
        merger.lock(1e18);

        vm.expectRevert(FPISMerger.NotYetUnlocked.selector);
        merger.unlock(alice);

        skipWithBlock(3 * 365 * 86_400);

        hoax(alice);
        vm.expectRevert(FPISMerger.AlreadyUnlocked.selector);
        merger.lock(1e18);

        deal(address(FXS), address(merger), 10e18);
        merger.unlock(alice);

        vm.expectRevert(FPISMerger.UserAlreadyUnlocked.selector);
        merger.unlock(alice);
        assertEq(FPIS.balanceOf(address(merger)), 2e18);
        assertEq(FXS.balanceOf(alice), 2e18);
    }

    function test_manyLocks() public {
        setUpFraxtalMainnet();
        deal(address(FPIS), alice, 1000e18);
        hoax(alice);
        FPIS.approve(address(merger), 1000e18);

        for (uint256 i = 0; i < 100; ++i) {
            hoax(alice);
            merger.lock(1e18);
            skipWithBlock(3600);
        }

        skipWithBlock(4 * 365 * 86_400);
        deal(address(FXS), address(merger), 1000e18);
        merger.unlock(alice);
        assertEq(FPIS.balanceOf(address(merger)), 100e18);
        assertEq(FXS.balanceOf(alice), 100e18);
    }

    function test_balanceOf() public {
        setUpFraxtalMainnet();
        deal(address(FPIS), alice, 1000e18);
        hoax(alice);
        FPIS.approve(address(merger), 1000e18);
        uint256 amount = 1e18;
        hoax(alice);
        merger.lock(amount);
        assertEq(merger.balanceOf(alice, merger.unlockTime()), 0);
        assertEq(merger.balanceOf(alice, merger.unlockTime() + 1), 0);
        assertEq(merger.balanceOf(alice, merger.unlockTime() - 1), amount + amount * 3 / (4 * 365 * 86_400));
        assertEq(merger.balanceOf(alice, merger.unlockTime() - 365 * 86_400), amount + amount * 3 / 4);
        assertEq(merger.balanceOf(alice, merger.unlockTime() - 2 * 365 * 86_400), amount + amount * 2 * 3 / 4);
        assertEq(merger.balanceOf(alice, merger.unlockTime() - 3 * 365 * 86_400), amount + amount * 3 * 3 / 4);
        assertEq(merger.balanceOf(alice, merger.unlockTime() - 4 * 365 * 86_400), amount + amount * 4 * 3 / 4);
        for (uint256 i = 0; i < 101; ++i) {
            assertEq(merger.balanceOf(alice), amount + (merger.unlockTime() - block.timestamp) * amount * 3 / (4 * 365 * 86_400));
            skipWithBlock(24 * 3600);
        }
        for (uint256 i = 0; i < 101; ++i) {
            assertEq(merger.balanceOf(alice), amount + (merger.unlockTime() - block.timestamp) * amount * 3 / (4 * 365 * 86_400));
            skipWithBlock(24 * 3600);
            hoax(alice);
            merger.lock(1e18);
            amount += 1e18;
        }
    }

    function test_balanceOfAt() public {
        setUpFraxtalMainnet();
        deal(address(FPIS), alice, 1000e18);
        hoax(alice);
        FPIS.approve(address(merger), 1000e18);
        uint256 amount = 1e18;
        hoax(alice);
        merger.lock(amount);
        vm.expectRevert(FPISMerger.InvalidBlockNumber.selector);
        merger.balanceOfAt(alice, block.number + 1);
        assertEq(merger.balanceOfAt(alice, block.number), merger.balanceOf(alice, block.timestamp));
        assertEq(merger.balanceOfAt(alice, block.number - 1), 0);
        skipWithBlock(1000);
        assertEq(merger.balanceOfAt(alice, block.number), merger.balanceOf(alice, block.timestamp));
        assertEq(merger.balanceOfAt(alice, block.number - 500), merger.balanceOf(alice, block.timestamp - 1000));
        assertEq(merger.balanceOfAt(alice, block.number - 501), 0);
        uint256 savedBalance = merger.balanceOfAt(alice, block.number - 1);
        hoax(alice);
        merger.lock(amount);
        assertEq(merger.balanceOfAt(alice, block.number), merger.balanceOf(alice, block.timestamp));
        assertEq(merger.balanceOfAt(alice, block.number - 1), savedBalance);
    }

    function test_invariants() public {
        setUpFraxtalMainnet();
        deal(address(FPIS), alice, 1000e18);
        deal(address(FPIS), bob, 1000e18);
        deal(address(FPIS), claire, 1000e18);
        deal(address(FPIS), dave, 1000e18);
        hoax(alice);
        FPIS.approve(address(merger), 1000e18);
        hoax(bob);
        FPIS.approve(address(merger), 1000e18);
        hoax(claire);
        FPIS.approve(address(merger), 1000e18);
        hoax(dave);
        FPIS.approve(address(merger), 1000e18);
        checkInvariants();
        for (int256 i = 0; i < 10; i++) {
            hoax(alice);
            merger.lock(1e18);
            checkInvariants();
            skipWithBlock(24 * 3600);
            checkInvariants();
            hoax(bob);
            merger.lock(2e18);
            checkInvariants();
            skipWithBlock(24 * 3600);
            checkInvariants();
            hoax(claire);
            merger.lock(3e18);
            checkInvariants();
            skipWithBlock(24 * 3600);
            checkInvariants();
            hoax(dave);
            merger.lock(4e18);
            checkInvariants();
            skipWithBlock(24 * 3600);
            checkInvariants();
        }
    }

    function checkInvariants() public {
        uint256 sumAmount;
        sumAmount += merger.locked(alice).amount;
        sumAmount += merger.locked(bob).amount;
        sumAmount += merger.locked(claire).amount;
        sumAmount += merger.locked(dave).amount;
        assertEq(sumAmount, FPIS.balanceOf(address(merger)));
        assertEq(sumAmount, merger.totalLocked());

        uint256 sumBalance;
        sumBalance += merger.balanceOf(alice);
        sumBalance += merger.balanceOf(bob);
        sumBalance += merger.balanceOf(claire);
        sumBalance += merger.balanceOf(dave);
        assertApproxEqAbs(sumBalance, merger.totalSupply(block.timestamp), 1000);

        uint256 sumBalance2;
        sumBalance2 += merger.balanceOf(alice, block.timestamp + 1000);
        sumBalance2 += merger.balanceOf(bob, block.timestamp + 1000);
        sumBalance2 += merger.balanceOf(claire, block.timestamp + 1000);
        sumBalance2 += merger.balanceOf(dave, block.timestamp + 1000);
        assertApproxEqAbs(sumBalance2, merger.totalSupply(block.timestamp + 1000), 1000);

        uint256 sumBalance3;
        sumBalance3 += merger.balanceOfAt(alice, block.number - 24 * 3600);
        sumBalance3 += merger.balanceOfAt(bob, block.number - 24 * 3600);
        sumBalance3 += merger.balanceOfAt(claire, block.number - 24 * 3600);
        sumBalance3 += merger.balanceOfAt(dave, block.number - 24 * 3600);
        assertApproxEqAbs(sumBalance3, merger.totalSupplyAt(block.number - 24 * 3600), 1000);
    }

    function skipWithBlock(uint256 time) public {
        skip(time);
        vm.roll(startBlockNumber + (block.timestamp - startTimestamp) / 2);
    }
}
