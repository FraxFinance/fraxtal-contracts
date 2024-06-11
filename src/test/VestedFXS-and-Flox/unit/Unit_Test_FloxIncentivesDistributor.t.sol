// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { DeployVestedFXS } from "src/script/VestedFXS-and-Flox/DeployVestedFXS.s.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { FloxIncentivesDistributor } from "src/contracts/VestedFXS-and-Flox/Flox/FloxIncentivesDistributor.sol";
import { IFloxEvents } from "src/contracts/VestedFXS-and-Flox/Flox/IFloxEvents.sol";
import { IFloxStructs } from "src/contracts/VestedFXS-and-Flox/Flox/IFloxStructs.sol";

import { DeployVestedFXS } from "src/script/VestedFXS-and-Flox/DeployVestedFXS.s.sol";

contract Unit_Test_FloxIncentivesDistributor is BaseTestVeFXS, IFloxEvents, IFloxStructs {
    function setUp() public {
        defaultSetup();

        // token = new MintableBurnableTestERC20("mockFXS", "mFXS");
        // (vestedFXS, vestedFXSUtils) = (new DeployVestedFXS()).runTest(address(token), "VestedFXS");
        // flox = new FloxIncentivesDistributor(address(vestedFXS), address(token));

        token.mint(address(flox), 1000e18);
        token.mint(bob, 1000e18);
        hoax(bob);
        token.approve(address(vestedFXS), 1000e18);
        token.mint(alice, 1000e18);
        hoax(alice);
        token.approve(address(vestedFXS), 1000e18);
        vestedFXS.setFloxContributor(address(this), true);
        vestedFXS.setFloxContributor(address(flox), true);
        flox.addContributor(address(this));
    }

    function test_ProposeNewAdmin() public {
        assertEq(flox.admin(), address(this));
        vm.expectEmit(true, true, false, true);
        emit FutureAdminProposed(address(this), bob);
        flox.proposeNewAdmin(bob);
        assertEq(flox.futureAdmin(), bob);

        vm.expectRevert(FloxIncentivesDistributor.NotAdmin.selector);
        hoax(bob);
        flox.proposeNewAdmin(alice);

        vm.expectRevert(FloxIncentivesDistributor.CannotAppointZeroAddress.selector);
        flox.proposeNewAdmin(address(0));
    }

    function test_AcceptAdmin() public {
        flox.proposeNewAdmin(bob);
        vm.expectEmit(true, true, false, true);
        emit NewAdmin(address(this), bob);
        hoax(bob);
        flox.acceptAdmin();
        assertEq(flox.admin(), bob);
        assertEq(flox.futureAdmin(), address(0));

        vm.expectRevert(FloxIncentivesDistributor.NotFutureAdmin.selector);
        hoax(bob);
        flox.acceptAdmin();
    }

    function test_AddContributor() public {
        assertFalse(flox.isContributor(bob));
        vm.expectEmit(true, false, false, true);
        emit ContributorAdded(bob);
        flox.addContributor(bob);
        assertTrue(flox.isContributor(bob));

        vm.expectRevert(FloxIncentivesDistributor.NotAdmin.selector);
        hoax(bob);
        flox.addContributor(alice);

        vm.expectRevert(FloxIncentivesDistributor.ContributorAlreadyAdded.selector);
        flox.addContributor(bob);

        vm.expectRevert(FloxIncentivesDistributor.CannotAppointZeroAddress.selector);
        flox.addContributor(address(0));
    }

    function test_RemoveContributor() public {
        flox.addContributor(bob);
        assertTrue(flox.isContributor(bob));
        vm.expectEmit(true, false, false, true);
        emit ContributorRemoved(bob);
        flox.removeContributor(bob);
        assertFalse(flox.isContributor(bob));

        vm.expectRevert(FloxIncentivesDistributor.NotAdmin.selector);
        hoax(bob);
        flox.removeContributor(alice);

        vm.expectRevert(FloxIncentivesDistributor.ContributorAlreadyRemoved.selector);
        flox.removeContributor(bob);
    }

    function test_SetNewLockDuration() public {
        assertEq(flox.newLockDuration(), MAXTIME_UINT128);
        vm.expectEmit(false, false, false, true);
        emit NewLockDurationUpdated(86_400);
        flox.setNewLockDuration(86_400);
        assertEq(flox.newLockDuration(), 86_400);

        vm.expectRevert(FloxIncentivesDistributor.NotAdmin.selector);
        hoax(bob);
        flox.setNewLockDuration(86_400);

        vm.expectRevert(FloxIncentivesDistributor.AttemptingToSetTooBigLockTime.selector);
        flox.setNewLockDuration(MAXTIME_UINT128 + 1);
    }

    function test_AllocateIncentivesToExistingLocks() public {
        assertEq(flox.incentivesEpoch(), 0);

        IncentivesInput[] memory inputs = new IncentivesInput[](2);
        inputs[0] = IncentivesInput({ recipient: bob, lockIndex: 0, amount: 100e18 });
        inputs[1] = IncentivesInput({ recipient: alice, lockIndex: 0, amount: 200e18 });

        uint128 unlockTimestamp = ((uint128(block.timestamp) + MAXTIME_UINT128) / WEEK_UINT128) * WEEK_UINT128;

        hoax(bob);
        vestedFXS.createLock(bob, 1000e18, unlockTimestamp);
        hoax(alice);
        vestedFXS.createLock(alice, 1000e18, unlockTimestamp);

        vm.expectEmit(true, false, false, true, address(flox));
        emit IncentiveAllocated(bob, 100e18, 0);
        vm.expectEmit(true, false, false, true, address(flox));
        emit IncentiveAllocated(alice, 200e18, 0);

        flox.allocateIncentivesToExistingLocks(inputs);

        assertEq(flox.incentivesEpoch(), 0);

        (,, uint256 totalIncentives, uint256 totalRecipients,) = flox.incentivesStats(0);

        assertEq(totalIncentives, 300e18);
        assertEq(totalRecipients, 2);

        vm.expectRevert(FloxIncentivesDistributor.NotAFloxContributor.selector);
        hoax(bob);
        flox.allocateIncentivesToExistingLocks(inputs);
    }

    function test_AllocateIncentivesToNewLocks() public {
        assertEq(flox.incentivesEpoch(), 0);

        IncentivesInput[] memory inputs = new IncentivesInput[](2);
        inputs[0] = IncentivesInput({ recipient: bob, lockIndex: 42, amount: 100e18 });
        inputs[1] = IncentivesInput({ recipient: alice, lockIndex: 42, amount: 200e18 });

        vm.expectEmit(true, false, false, true, address(flox));
        emit IncentiveAllocated(bob, 100e18, 0);
        vm.expectEmit(true, false, false, true, address(flox));
        emit IncentiveAllocated(alice, 200e18, 0);

        flox.allocateIncentivesToNewLocks(inputs);

        assertEq(flox.incentivesEpoch(), 0);

        (,, uint256 totalIncentives, uint256 totalRecipients,) = flox.incentivesStats(0);

        assertEq(totalIncentives, 300e18);
        assertEq(totalRecipients, 2);

        vm.expectRevert(FloxIncentivesDistributor.NotAFloxContributor.selector);
        hoax(bob);
        flox.allocateIncentivesToNewLocks(inputs);
    }

    function test_ProvideEpochStats() public {
        assertEq(flox.incentivesEpoch(), 0);

        vm.expectEmit(false, false, false, true);
        emit IncentiveStatsUpdate(0, 0, 6000, 0, 0, bytes32("0x42"));
        flox.provideEpochStats(0, 6000, bytes32("0x42"));

        assertEq(flox.incentivesEpoch(), 1);

        (uint128 startBlock, uint128 endBlock,,, bytes32 proof) = flox.incentivesStats(0);
        assertEq(startBlock, 0);
        assertEq(endBlock, 6000);
        assertEq(proof, bytes32("0x42"));

        vm.expectRevert(FloxIncentivesDistributor.NotAFloxContributor.selector);
        hoax(bob);
        flox.provideEpochStats(42, 6000, bytes32("0x42"));

        vm.expectRevert(abi.encodeWithSelector(FloxIncentivesDistributor.IncentivesEpochStartBlockMismatch.selector, 7, 6001));
        flox.provideEpochStats(7, 6001, bytes32("0x42"));

        vm.expectRevert(FloxIncentivesDistributor.EndBlockBeforeStartBlock.selector);
        flox.provideEpochStats(6001, 6001, bytes32("0x42"));
    }
}
