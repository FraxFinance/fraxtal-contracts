// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FloxConverter, FloxConverterStructs } from "src/contracts/VestedFXS-and-Flox/Flox/FloxConverter.sol";
import { OwnedUpgradeable } from "src/contracts/VestedFXS-and-Flox/Flox/OwnedUpgradeable.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_FloxConverter is BaseTestVeFXS, FloxConverterStructs, OwnedUpgradeable {
    function floxCapSetup() public {
        console.log("defaultSetup() called");
        super.defaultSetup();

        // Mint FXS to the test users
        token.mint(alice, 100e18);
        token.mint(bob, 100e18);

        // Set frank as the Flox contributor
        floxConverter.addFloxContributor(frank);
    }

    function test_commitTransferOwnership() public {
        floxCapSetup();

        vm.expectEmit(true, false, false, true);
        emit OwnerNominated(bob);
        floxConverter.nominateNewOwner(bob);
        assertEq(floxConverter.nominatedOwner(), bob);

        vm.expectRevert(OnlyOwner.selector);
        hoax(bob);
        floxConverter.nominateNewOwner(bob);
    }

    function test_acceptOwnership() public {
        floxCapSetup();

        floxConverter.nominateNewOwner(bob);
        vm.expectEmit(true, true, false, true);
        emit OwnerChanged(address(this), bob);
        hoax(bob);
        floxConverter.acceptOwnership();
        assertEq(floxConverter.owner(), bob);

        vm.expectRevert(InvalidOwnershipAcceptance.selector);
        hoax(alice);
        floxConverter.acceptOwnership();

        vm.expectRevert(OwnerCannotBeZeroAddress.selector);
        hoax(bob);
        floxConverter.nominateNewOwner(address(0));
    }

    function test_stopOperation() public {
        floxCapSetup();

        assertFalse(floxConverter.isPaused());

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(true, block.timestamp);
        hoax(frank);
        floxConverter.stopOperation();
        assertTrue(floxConverter.isPaused());

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.stopOperation();
    }

    function test_restartOperation() public {
        floxCapSetup();

        assertFalse(floxConverter.isPaused());

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(true, block.timestamp);
        hoax(frank);
        floxConverter.stopOperation();
        assertTrue(floxConverter.isPaused());

        vm.expectRevert(OnlyOwner.selector);
        hoax(frank);
        floxConverter.restartOperation();

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(false, block.timestamp);
        floxConverter.restartOperation();

        vm.expectRevert(ContractOperational.selector);
        floxConverter.restartOperation();
    }

    function test_addFloxContributor() public {
        floxCapSetup();

        assertFalse(floxConverter.isFloxContributor(bob));

        vm.expectEmit(true, false, false, true);
        emit FloxContributorAdded(bob);
        floxConverter.addFloxContributor(bob);

        assertTrue(floxConverter.isFloxContributor(bob));

        vm.expectRevert(OnlyOwner.selector);
        hoax(bob);
        floxConverter.addFloxContributor(alice);

        vm.expectRevert(AlreadyFloxContributor.selector);
        floxConverter.addFloxContributor(bob);
    }

    function test_removeFloxContributor() public {
        floxCapSetup();

        floxConverter.addFloxContributor(bob);

        assertTrue(floxConverter.isFloxContributor(bob));

        vm.expectEmit(true, false, false, true);
        emit FloxContributorRemoved(bob);
        floxConverter.removeFloxContributor(bob);

        assertFalse(floxConverter.isFloxContributor(bob));

        vm.expectRevert(OnlyOwner.selector);
        hoax(frank);
        floxConverter.removeFloxContributor(bob);

        vm.expectRevert(NotFloxContributor.selector);
        floxConverter.removeFloxContributor(bob);
    }

    function test_remainingFraxAvailable() public {
        floxCapSetup();

        assertEq(floxConverter.remainingFraxAvailable(), 0);

        deal(address(floxConverter), 100e18);
        assertEq(floxConverter.remainingFraxAvailable(), 100e18);
    }

    function test_weeklyAvailableFrax() public {
        floxCapSetup();

        assertEq(floxConverter.weeklyAvailableFrax(), 0);

        uint256 expectedWeeklyAvailableFrax = uint256(100_000_000_000_000_000_000 * 7 days) / 365 days;

        floxConverter.setYearlyFraxDistribution(100e18);
        assertEq(floxConverter.weeklyAvailableFrax(), expectedWeeklyAvailableFrax);
    }

    function test_getCurrentUserRedeemalEpochFxtlPoints() public {
        floxCapSetup();

        assertEq(floxConverter.getCurrentUserRedeemalEpochFxtlPoints(alice), 2e18);
        assertEq(floxConverter.getCurrentUserRedeemalEpochFxtlPoints(bob), 2e18);

        token.mint(alice, 100e18);
        token.mint(bob, 100e17);

        assertEq(floxConverter.getCurrentUserRedeemalEpochFxtlPoints(alice), 4e18);
        assertEq(floxConverter.getCurrentUserRedeemalEpochFxtlPoints(bob), 22e17);
    }

    function test_bulkGetCurrentUserRedeemalEpochFxtlPoints() public {
        floxCapSetup();

        address[] memory users = new address[](2);
        users[0] = alice;
        users[1] = bob;

        uint256[] memory fxtlPoints = new uint256[](2);

        fxtlPoints = floxConverter.bulkGetCurrentUserRedeemalEpochFxtlPoints(users);
        assertEq(fxtlPoints[0], 2e18);
        assertEq(fxtlPoints[1], 2e18);

        token.mint(alice, 100e18);
        token.mint(bob, 100e17);

        fxtlPoints = floxConverter.bulkGetCurrentUserRedeemalEpochFxtlPoints(users);
        assertEq(fxtlPoints[0], 4e18);
        assertEq(fxtlPoints[1], 22e17);
    }

    function test_getFraxAllocationFromFloxStakeUnits() public {
        floxCapSetup();

        floxConverter.setYearlyFraxDistribution(100e18);

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 2e18, 42);

        RedeemalEpoch memory redeemalEpoch;

        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized, redeemalEpoch.firstBlock, redeemalEpoch.lastBlock, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.firstBlock, 1);
        assertEq(redeemalEpoch.lastBlock, 1000);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 0);

        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(alice, 0, 2e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, alice, 2e18, 42);
        hoax(frank);
        floxConverter.updateUserData(alice, 2e18, 42);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized, redeemalEpoch.firstBlock, redeemalEpoch.lastBlock, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.firstBlock, 1);
        assertEq(redeemalEpoch.lastBlock, 1000);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 2e18);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 42);

        vm.expectRevert(UninitiatedRedeemalEpoch.selector);
        floxConverter.getFraxAllocationFromFloxStakeUnits(42, 2);

        uint256 expectedWeeklyAvailableFrax = uint256(100_000_000_000_000_000_000 * 7 days) / 365 days;
        uint256 projectedFraxAllocation = floxConverter.getFraxAllocationFromFloxStakeUnits(42, 1);
        assertEq(projectedFraxAllocation, expectedWeeklyAvailableFrax);

        projectedFraxAllocation = floxConverter.getFraxAllocationFromFloxStakeUnits(21, 1);
        assertEq(projectedFraxAllocation, expectedWeeklyAvailableFrax / 2);
    }

    function test_initiateRedeemalEpoch() public {
        floxCapSetup();

        uint256 expectedWeeklyAvailableFrax = uint256(100_000_000_000_000_000_000 * 7 days) / 365 days;
        floxConverter.setYearlyFraxDistribution(100e18);

        RedeemalEpoch memory redeemalEpoch;

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized, redeemalEpoch.firstBlock, redeemalEpoch.lastBlock, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertFalse(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.firstBlock, 0);
        assertEq(redeemalEpoch.lastBlock, 0);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 0);

        vm.expectEmit(false, false, false, true);
        emit RedeemalEpochInitiated(1, 1, 1000, expectedWeeklyAvailableFrax);
        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized, redeemalEpoch.firstBlock, redeemalEpoch.lastBlock, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.firstBlock, 1);
        assertEq(redeemalEpoch.lastBlock, 1000);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 0);

        vm.expectRevert(InvalidLastBlockNumber.selector);
        hoax(frank);
        floxConverter.initiateRedeemalEpoch(0);

        vm.expectRevert(InvalidLastBlockNumber.selector);
        hoax(frank);
        floxConverter.initiateRedeemalEpoch(uint64(block.number + 10));

        hoax(frank);
        floxConverter.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);
    }

    function test_updateUserData() public {
        floxCapSetup();

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 2e18, 42);

        RedeemalEpoch memory redeemalEpoch;

        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized, redeemalEpoch.firstBlock, redeemalEpoch.lastBlock, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.firstBlock, 1);
        assertEq(redeemalEpoch.lastBlock, 1000);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 0);

        RedeemalEpochUserData memory epochUserData;
        UserData memory userData;

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 0);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 0);
        assertEq(userData.totalFxtlPointsRedeemed, 0);
        assertEq(userData.totalFraxReceived, 0);

        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(alice, 0, 2e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, alice, 2e18, 42);
        hoax(frank);
        floxConverter.updateUserData(alice, 2e18, 42);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 42);
        assertEq(userData.totalFxtlPointsRedeemed, 2e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 2e18);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 42);

        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(alice, 2e18, 1e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, alice, 1e18, 100);
        hoax(frank);
        floxConverter.updateUserData(alice, 1e18, 100);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 1e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 100);
        assertEq(userData.totalFxtlPointsRedeemed, 1e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 1e18);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 100);

        vm.expectRevert(InvalidFxtlPointsAmount.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 0, 100);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.updateUserData(alice, 1e18, 100);

        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        vm.expectRevert(EpochAlreadyPopulated.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 1e18, 100);

        hoax(frank);
        floxConverter.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 1e18, 100);
    }

    function test_bulkUpdateUserData() public {
        floxCapSetup();

        address[] memory users = new address[](2);
        users[0] = alice;
        users[1] = bob;
        uint256[] memory fxtlPoints = new uint256[](2);
        fxtlPoints[0] = 2e18;
        fxtlPoints[1] = 1e18;
        uint256[] memory floxStakeUnits = new uint256[](2);
        floxStakeUnits[0] = 42;
        floxStakeUnits[1] = 100;

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        RedeemalEpoch memory redeemalEpoch;

        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized, redeemalEpoch.firstBlock, redeemalEpoch.lastBlock, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.firstBlock, 1);
        assertEq(redeemalEpoch.lastBlock, 1000);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 0);

        RedeemalEpochUserData memory epochUserData;
        UserData memory userData;

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 0);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 0);
        assertEq(userData.totalFxtlPointsRedeemed, 0);
        assertEq(userData.totalFraxReceived, 0);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, bob);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(bob);

        assertEq(epochUserData.fxtlPointsRedeemed, 0);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 0);
        assertEq(userData.totalFxtlPointsRedeemed, 0);
        assertEq(userData.totalFraxReceived, 0);

        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(alice, 0, 2e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, alice, 2e18, 42);
        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(bob, 0, 1e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, bob, 1e18, 100);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 42);
        assertEq(userData.totalFxtlPointsRedeemed, 2e18);
        assertEq(userData.totalFraxReceived, 0);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, bob);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(bob);

        assertEq(epochUserData.fxtlPointsRedeemed, 1e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 100);
        assertEq(userData.totalFxtlPointsRedeemed, 1e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 3e18);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 142);

        fxtlPoints[0] = 3e18;
        fxtlPoints[1] = 4e18;
        floxStakeUnits[0] = 200;
        floxStakeUnits[1] = 50;

        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(alice, 2e18, 3e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, alice, 3e18, 200);
        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(bob, 1e18, 4e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, bob, 4e18, 50);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 3e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 200);
        assertEq(userData.totalFxtlPointsRedeemed, 3e18);
        assertEq(userData.totalFraxReceived, 0);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, bob);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(bob);

        assertEq(epochUserData.fxtlPointsRedeemed, 4e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 50);
        assertEq(userData.totalFxtlPointsRedeemed, 4e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 7e18);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 250);

        vm.expectRevert(InvalidArrayLength.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, new uint256[](1));

        vm.expectRevert(InvalidArrayLength.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, new uint256[](1), floxStakeUnits);

        fxtlPoints[1] = 0;

        vm.expectRevert(InvalidFxtlPointsAmount.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        vm.expectRevert(EpochAlreadyPopulated.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        hoax(frank);
        floxConverter.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);
    }

    function test_markRedeemalEpochAsPopulated() public {
        floxCapSetup();

        RedeemalEpoch memory redeemalEpoch;

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertFalse(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 0);

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);

        address[] memory users = new address[](2);
        users[0] = alice;
        users[1] = bob;
        uint256[] memory fxtlPoints = new uint256[](2);
        fxtlPoints[0] = 2e18;
        fxtlPoints[1] = 1e18;
        uint256[] memory floxStakeUnits = new uint256[](2);
        floxStakeUnits[0] = 42;
        floxStakeUnits[1] = 100;

        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 3e18);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 142);

        vm.expectEmit(false, false, false, true);
        emit RedeemalEpochPopulated(1, 1, 1000, 142);
        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,, redeemalEpoch.totalFxtlPointsRedeemed, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertTrue(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.totalFxtlPointsRedeemed, 3e18);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 142);

        vm.expectRevert(EpochAlreadyPopulated.selector);
        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.markRedeemalEpochAsPopulated();

        hoax(frank);
        floxConverter.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();
    }

    function test_distributeFrax() public {
        floxCapSetup();

        RedeemalEpoch memory redeemalEpoch;

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,,, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertFalse(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 0);

        Rejector rejector = new Rejector();
        ReentrantUser reentrantUser = new ReentrantUser(address(floxConverter));

        address[] memory users = new address[](4);
        users[0] = alice;
        users[1] = bob;
        users[2] = address(rejector);
        users[3] = address(reentrantUser);
        uint256[] memory fxtlPoints = new uint256[](4);
        fxtlPoints[0] = 2e18;
        fxtlPoints[1] = 1e18;
        fxtlPoints[2] = 1e18;
        fxtlPoints[3] = 1e18;
        uint256[] memory floxStakeUnits = new uint256[](4);
        floxStakeUnits[0] = 50;
        floxStakeUnits[1] = 100;
        floxStakeUnits[2] = 50;
        floxStakeUnits[3] = 50;

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.distributeFrax(users);

        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);

        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        vm.expectRevert(EpochNotPopulated.selector);
        hoax(frank);
        floxConverter.distributeFrax(users);

        floxConverter.setYearlyFraxDistribution(100e18);
        deal(address(floxConverter), 100e18);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,,, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 250);

        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,,, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertTrue(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertEq(redeemalEpoch.totalFraxDistributed, 0);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 250);

        address[] memory usersToDistribute = new address[](2);
        usersToDistribute[0] = alice;
        usersToDistribute[1] = address(rejector);

        vm.expectRevert(abi.encodeWithSelector(DistributionFailed.selector, address(rejector)));
        hoax(frank);
        floxConverter.distributeFrax(usersToDistribute);

        usersToDistribute[1] = address(reentrantUser);
        vm.expectRevert(abi.encodeWithSelector(DistributionFailed.selector, address(reentrantUser)));
        hoax(frank);
        floxConverter.distributeFrax(usersToDistribute);

        usersToDistribute[1] = bob;

        vm.expectEmit(true, false, false, true);
        emit DistributionAllocated(alice, uint256(100e18 * 50 * 7 days) / ((365 days * 250)));
        vm.expectEmit(true, false, false, true);
        emit DistributionAllocated(bob, uint256(100e18 * 100 * 7 days) / ((365 days * 250)));
        hoax(frank);
        floxConverter.distributeFrax(usersToDistribute);

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,,, redeemalEpoch.totalFraxDistributed, redeemalEpoch.totalFloxStakeUnits) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertTrue(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);
        assertApproxEqAbs(redeemalEpoch.totalFraxDistributed, uint256(100e18 * 150 * 7 days) / ((365 days * 250)), 2);
        assertEq(redeemalEpoch.totalFloxStakeUnits, 250);

        assertApproxEqAbs(floxConverter.remainingFraxAvailable(), 100e18 - (uint256(100e18 * 150 * 7 days) / ((365 days * 250))), 2);
        assertApproxEqAbs(address(floxConverter).balance, 100e18 - (uint256(100e18 * 150 * 7 days) / ((365 days * 250))), 2);

        assertEq(floxConverter.totalFxtlPointsRedeemed(), 5e18);

        RedeemalEpochUserData memory epochUserData;
        UserData memory userData;

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertApproxEqAbs(epochUserData.fraxReceived, uint256(100e18 * 50 * 7 days) / ((365 days * 250)), 2);
        assertEq(epochUserData.floxStakeUnits, 50);
        assertEq(userData.totalFxtlPointsRedeemed, 2e18);
        assertApproxEqAbs(userData.totalFraxReceived, uint256(100e18 * 50 * 7 days) / ((365 days * 250)), 2);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, bob);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(bob);

        assertEq(epochUserData.fxtlPointsRedeemed, 1e18);
        assertApproxEqAbs(epochUserData.fraxReceived, uint256(100e18 * 100 * 7 days) / ((365 days * 250)), 2);
        assertEq(epochUserData.floxStakeUnits, 100);
        assertEq(userData.totalFxtlPointsRedeemed, 1e18);
        assertApproxEqAbs(userData.totalFraxReceived, uint256(100e18 * 100 * 7 days) / ((365 days * 250)), 2);

        vm.expectRevert(abi.encodeWithSelector(AlreadyDistributed.selector, address(alice)));
        hoax(frank);
        floxConverter.distributeFrax(usersToDistribute);

        hoax(frank);
        floxConverter.finalizeRedeemalEpoch();

        hoax(frank);
        floxConverter.initiateRedeemalEpoch(2000);

        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        vm.expectEmit(true, false, false, true);
        emit DistributionAllocated(alice, uint256(100e18 * 50 * 7 days) / ((365 days * 250)));
        vm.expectEmit(true, false, false, true);
        emit DistributionAllocated(bob, uint256(100e18 * 100 * 7 days) / ((365 days * 250)));
        hoax(frank);
        floxConverter.distributeFrax(usersToDistribute);

        assertApproxEqAbs(floxConverter.remainingFraxAvailable(), 100e18 - (uint256(100e18 * 150 * 7 days * 2) / ((365 days * 250))), 2);
        assertApproxEqAbs(address(floxConverter).balance, 100e18 - (uint256(100e18 * 150 * 7 days * 2) / ((365 days * 250))), 2);

        assertEq(floxConverter.totalFxtlPointsRedeemed(), 10e18);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertApproxEqAbs(epochUserData.fraxReceived, uint256(100e18 * 50 * 7 days) / ((365 days * 250)), 2);
        assertEq(epochUserData.floxStakeUnits, 50);
        assertEq(userData.totalFxtlPointsRedeemed, 4e18);
        assertApproxEqAbs(userData.totalFraxReceived, uint256(100e18 * 50 * 7 days * 2) / ((365 days * 250)), 2);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redeemalEpochUserData(1, bob);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(bob);

        assertEq(epochUserData.fxtlPointsRedeemed, 1e18);
        assertApproxEqAbs(epochUserData.fraxReceived, uint256(100e18 * 100 * 7 days) / ((365 days * 250)), 2);
        assertEq(epochUserData.floxStakeUnits, 100);
        assertEq(userData.totalFxtlPointsRedeemed, 2e18);
        assertApproxEqAbs(userData.totalFraxReceived, uint256(100e18 * 100 * 7 days * 2) / ((365 days * 250)), 2);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.distributeFrax(usersToDistribute);

        hoax(frank);
        floxConverter.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.distributeFrax(usersToDistribute);
    }

    function test_finalizeRedeemalEpoch() public {
        floxCapSetup();

        assertEq(floxConverter.latestAllocatedDistributionEpoch(), 0);

        RedeemalEpoch memory redeemalEpoch;

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,,,,) = floxConverter.redeemalEpochs(1);

        assertFalse(redeemalEpoch.initiated);
        assertFalse(redeemalEpoch.populated);
        assertFalse(redeemalEpoch.finalized);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.finalizeRedeemalEpoch();

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.finalizeRedeemalEpoch();

        hoax(frank);
        floxConverter.initiateRedeemalEpoch(1000);

        vm.expectRevert(EpochNotPopulated.selector);
        hoax(frank);
        floxConverter.finalizeRedeemalEpoch();

        hoax(frank);
        floxConverter.markRedeemalEpochAsPopulated();

        vm.expectEmit(false, false, false, true);
        emit RedeemalEpochFinalized(1);
        hoax(frank);
        floxConverter.finalizeRedeemalEpoch();

        (redeemalEpoch.initiated, redeemalEpoch.populated, redeemalEpoch.finalized,,,,,) = floxConverter.redeemalEpochs(1);

        assertTrue(redeemalEpoch.initiated);
        assertTrue(redeemalEpoch.populated);
        assertTrue(redeemalEpoch.finalized);
        assertEq(floxConverter.latestAllocatedDistributionEpoch(), 1);

        hoax(frank);
        floxConverter.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.finalizeRedeemalEpoch();
    }

    function test_setYearlyFraxDistribution() public {
        floxCapSetup();

        vm.expectRevert(OnlyOwner.selector);
        hoax(frank);
        floxConverter.setYearlyFraxDistribution(100e18);

        vm.expectRevert(ZeroYearlyFraxDistribution.selector);
        floxConverter.setYearlyFraxDistribution(0);

        vm.expectEmit(false, false, false, true);
        emit YearlyFraxDistributionUpdated(0, 100e18);
        floxConverter.setYearlyFraxDistribution(100e18);

        assertEq(floxConverter.yearlyFraxDistribution(), 100e18);
    }
}

contract Rejector {
    receive() external payable {
        revert("Rejected");
    }
}

contract ReentrantUser {
    address public converter;

    constructor(address _converter) {
        converter = _converter;
    }

    receive() external payable {
        address[] memory array = new address[](1);
        array[0] = address(this);

        (bool success,) = converter.call(abi.encodeWithSignature("distributeFrax(address[])", array));
        require(success, "Reentrancy failed");
    }
}
