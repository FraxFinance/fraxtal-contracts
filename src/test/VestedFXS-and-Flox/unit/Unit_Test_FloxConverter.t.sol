// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FloxConverter, FloxConverterStructs } from "src/contracts/VestedFXS-and-Flox/Flox/FloxConverter.sol";
import { FloxCapacitor } from "src/contracts/VestedFXS-and-Flox/Flox/FloxCapacitor.sol";
import { OwnedUpgradeable } from "src/contracts/VestedFXS-and-Flox/Flox/OwnedUpgradeable.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_FloxConverter is BaseTestVeFXS, FloxConverterStructs, OwnedUpgradeable {
    function floxCapSetup() public {
        console.log("defaultSetup() called");
        super.defaultSetup();

        // Mint FXTL points to the test users
        token.mint(alice, 1e6);
        token.mint(bob, 1e6);

        // Set frank as the Flox contributor
        floxConverter.addFloxContributor(frank);

        vm.expectRevert(AlreadyInitialized.selector);
        floxConverter.initialize(bob, address(floxCap), address(token), "FloxConverter_v2.0.0");
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

    function test_getCurrentUserRedemptionEpochFxtlPoints() public {
        floxCapSetup();

        assertEq(floxConverter.getCurrentUserRedemptionEpochFxtlPoints(alice), 2e4);
        assertEq(floxConverter.getCurrentUserRedemptionEpochFxtlPoints(bob), 2e4);

        token.mint(alice, 1e6);
        token.mint(bob, 1e5);

        assertEq(floxConverter.getCurrentUserRedemptionEpochFxtlPoints(alice), 4e4);
        assertEq(floxConverter.getCurrentUserRedemptionEpochFxtlPoints(bob), 22e3);
    }

    function test_bulkGetCurrentUserRedemptionEpochFxtlPoints() public {
        floxCapSetup();

        address[] memory users = new address[](2);
        users[0] = alice;
        users[1] = bob;

        uint256[] memory fxtlPoints = new uint256[](2);

        fxtlPoints = floxConverter.bulkGetCurrentUserRedemptionEpochFxtlPoints(users);
        assertEq(fxtlPoints[0], 2e4);
        assertEq(fxtlPoints[1], 2e4);

        token.mint(alice, 1e6);
        token.mint(bob, 1e5);

        fxtlPoints = floxConverter.bulkGetCurrentUserRedemptionEpochFxtlPoints(users);
        assertEq(fxtlPoints[0], 4e4);
        assertEq(fxtlPoints[1], 22e3);
    }

    function test_calculateFloxStakeUnits() public {
        floxCapSetup();

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, address(alice)), abi.encode(10e18));

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, address(bob)), abi.encode(0));

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, claire), abi.encode(20e18));

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, dave), abi.encode(100e18));

        token.mint(claire, 1e6);
        token.mint(dave, 1e6);

        assertEq(floxConverter.calculateFloxStakeUnits(alice), 3e4);
        assertEq(floxConverter.calculateFloxStakeUnits(bob), 2e4);
        assertEq(floxConverter.calculateFloxStakeUnits(claire), 4e4);
        assertEq(floxConverter.calculateFloxStakeUnits(dave), 4e4);
        assertEq(floxConverter.calculateFloxStakeUnits(frank), 0);
    }

    function test_bulkCalculateFloxStakeUnits() public {
        floxCapSetup();

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, address(alice)), abi.encode(10e18));

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, address(bob)), abi.encode(0));

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, claire), abi.encode(20e18));

        vm.mockCall(address(floxConverter.FLOX_CAPACITOR()), abi.encodeWithSelector(FloxCapacitor.balanceOf.selector, dave), abi.encode(100e18));

        token.mint(claire, 1e6);
        token.mint(dave, 1e6);

        address[] memory users = new address[](5);
        users[0] = alice;
        users[1] = bob;
        users[2] = claire;
        users[3] = dave;
        users[4] = frank;

        uint256[] memory floxStakeUnits = floxConverter.bulkCalculateFloxStakeUnits(users);
        assertEq(floxStakeUnits[0], 3e4);
        assertEq(floxStakeUnits[1], 2e4);
        assertEq(floxStakeUnits[2], 4e4);
        assertEq(floxStakeUnits[3], 4e4);
        assertEq(floxStakeUnits[4], 0);
    }

    function test_getFraxAllocationFromFloxStakeUnits() public {
        floxCapSetup();

        floxConverter.setYearlyFraxDistribution(100e18);

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 2e18, 42);

        RedemptionEpoch memory redemptionEpoch;

        hoax(frank);
        floxConverter.initiateRedemptionEpoch(1000);

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized, redemptionEpoch.firstBlock, redemptionEpoch.lastBlock, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.firstBlock, 1);
        assertEq(redemptionEpoch.lastBlock, 1000);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 0);

        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(alice, 0, 2e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, alice, 2e18, 42);
        hoax(frank);
        floxConverter.updateUserData(alice, 2e18, 42);

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized, redemptionEpoch.firstBlock, redemptionEpoch.lastBlock, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.firstBlock, 1);
        assertEq(redemptionEpoch.lastBlock, 1000);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 2e18);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 42);

        vm.expectRevert(UninitiatedRedemptionEpoch.selector);
        floxConverter.getFraxAllocationFromFloxStakeUnits(42, 2);

        uint256 expectedWeeklyAvailableFrax = uint256(100_000_000_000_000_000_000 * 7 days) / 365 days;
        uint256 projectedFraxAllocation = floxConverter.getFraxAllocationFromFloxStakeUnits(42, 1);
        assertEq(projectedFraxAllocation, expectedWeeklyAvailableFrax);

        projectedFraxAllocation = floxConverter.getFraxAllocationFromFloxStakeUnits(21, 1);
        assertEq(projectedFraxAllocation, expectedWeeklyAvailableFrax / 2);
    }

    function test_initiateRedemptionEpoch() public {
        floxCapSetup();

        uint256 expectedWeeklyAvailableFrax = uint256(100_000_000_000_000_000_000 * 7 days) / 365 days;
        floxConverter.setYearlyFraxDistribution(100e18);

        RedemptionEpoch memory redemptionEpoch;

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized, redemptionEpoch.firstBlock, redemptionEpoch.lastBlock, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertFalse(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.firstBlock, 0);
        assertEq(redemptionEpoch.lastBlock, 0);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 0);

        vm.expectEmit(false, false, false, true);
        emit RedemptionEpochInitiated(1, 1, 1000, expectedWeeklyAvailableFrax);
        hoax(frank);
        floxConverter.initiateRedemptionEpoch(1000);

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized, redemptionEpoch.firstBlock, redemptionEpoch.lastBlock, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.firstBlock, 1);
        assertEq(redemptionEpoch.lastBlock, 1000);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 0);

        vm.expectRevert(InvalidLastBlockNumber.selector);
        hoax(frank);
        floxConverter.initiateRedemptionEpoch(0);

        vm.expectRevert(InvalidLastBlockNumber.selector);
        hoax(frank);
        floxConverter.initiateRedemptionEpoch(uint64(block.number + 10));

        hoax(frank);
        floxConverter.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.initiateRedemptionEpoch(1000);
    }

    function test_updateUserData() public {
        floxCapSetup();

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 2e18, 42);

        RedemptionEpoch memory redemptionEpoch;

        hoax(frank);
        floxConverter.initiateRedemptionEpoch(1000);

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized, redemptionEpoch.firstBlock, redemptionEpoch.lastBlock, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.firstBlock, 1);
        assertEq(redemptionEpoch.lastBlock, 1000);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 0);

        RedemptionEpochUserData memory epochUserData;
        UserData memory userData;

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

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

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 42);
        assertEq(userData.totalFxtlPointsRedeemed, 2e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 2e18);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 42);

        vm.expectEmit(true, false, false, true);
        emit UserStatsUpdated(alice, 2e18, 1e18);
        vm.expectEmit(true, true, false, true);
        emit UserEpochDataUpdated(1, alice, 1e18, 100);
        hoax(frank);
        floxConverter.updateUserData(alice, 1e18, 100);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 1e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 100);
        assertEq(userData.totalFxtlPointsRedeemed, 1e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 1e18);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 100);

        vm.expectRevert(InvalidFxtlPointsAmount.selector);
        hoax(frank);
        floxConverter.updateUserData(alice, 0, 100);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.updateUserData(alice, 1e18, 100);

        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();

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

        RedemptionEpoch memory redemptionEpoch;

        hoax(frank);
        floxConverter.initiateRedemptionEpoch(1000);

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized, redemptionEpoch.firstBlock, redemptionEpoch.lastBlock, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.firstBlock, 1);
        assertEq(redemptionEpoch.lastBlock, 1000);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 0);

        RedemptionEpochUserData memory epochUserData;
        UserData memory userData;

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 0);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 0);
        assertEq(userData.totalFxtlPointsRedeemed, 0);
        assertEq(userData.totalFraxReceived, 0);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, bob);

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

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 42);
        assertEq(userData.totalFxtlPointsRedeemed, 2e18);
        assertEq(userData.totalFraxReceived, 0);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, bob);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(bob);

        assertEq(epochUserData.fxtlPointsRedeemed, 1e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 100);
        assertEq(userData.totalFxtlPointsRedeemed, 1e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 3e18);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 142);

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

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 3e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 200);
        assertEq(userData.totalFxtlPointsRedeemed, 3e18);
        assertEq(userData.totalFraxReceived, 0);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, bob);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(bob);

        assertEq(epochUserData.fxtlPointsRedeemed, 4e18);
        assertEq(epochUserData.fraxReceived, 0);
        assertEq(epochUserData.floxStakeUnits, 50);
        assertEq(userData.totalFxtlPointsRedeemed, 4e18);
        assertEq(userData.totalFraxReceived, 0);

        (,,,,, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 7e18);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 250);

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
        floxConverter.markRedemptionEpochAsPopulated();

        vm.expectRevert(EpochAlreadyPopulated.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        hoax(frank);
        floxConverter.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);
    }

    function test_markRedemptionEpochAsPopulated() public {
        floxCapSetup();

        RedemptionEpoch memory redemptionEpoch;

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertFalse(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 0);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 0);

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();

        hoax(frank);
        floxConverter.initiateRedemptionEpoch(1000);

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

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 3e18);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 142);

        vm.expectEmit(false, false, false, true);
        emit RedemptionEpochPopulated(1, 1, 1000, 142);
        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,, redemptionEpoch.totalFxtlPointsRedeemed, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertTrue(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.totalFxtlPointsRedeemed, 3e18);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 142);

        vm.expectRevert(EpochAlreadyPopulated.selector);
        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.markRedemptionEpochAsPopulated();

        hoax(frank);
        floxConverter.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();
    }

    function test_distributeFrax() public {
        floxCapSetup();

        RedemptionEpoch memory redemptionEpoch;

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,,, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertFalse(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 0);

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
        floxConverter.initiateRedemptionEpoch(1000);

        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        vm.expectRevert(EpochNotPopulated.selector);
        hoax(frank);
        floxConverter.distributeFrax(users);

        floxConverter.setYearlyFraxDistribution(100e18);
        deal(address(floxConverter), 100e18);

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,,, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 250);

        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,,, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertTrue(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertEq(redemptionEpoch.totalFraxDistributed, 0);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 250);

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

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,,, redemptionEpoch.totalFraxDistributed, redemptionEpoch.totalFloxStakeUnits) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertTrue(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);
        assertApproxEqAbs(redemptionEpoch.totalFraxDistributed, uint256(100e18 * 150 * 7 days) / ((365 days * 250)), 2);
        assertEq(redemptionEpoch.totalFloxStakeUnits, 250);

        assertApproxEqAbs(floxConverter.remainingFraxAvailable(), 100e18 - (uint256(100e18 * 150 * 7 days) / ((365 days * 250))), 2);
        assertApproxEqAbs(address(floxConverter).balance, 100e18 - (uint256(100e18 * 150 * 7 days) / ((365 days * 250))), 2);

        assertEq(floxConverter.totalFxtlPointsRedeemed(), 5e18);

        RedemptionEpochUserData memory epochUserData;
        UserData memory userData;

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertApproxEqAbs(epochUserData.fraxReceived, uint256(100e18 * 50 * 7 days) / ((365 days * 250)), 2);
        assertEq(epochUserData.floxStakeUnits, 50);
        assertEq(userData.totalFxtlPointsRedeemed, 2e18);
        assertApproxEqAbs(userData.totalFraxReceived, uint256(100e18 * 50 * 7 days) / ((365 days * 250)), 2);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, bob);

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
        floxConverter.finalizeRedemptionEpoch();

        hoax(frank);
        floxConverter.initiateRedemptionEpoch(2000);

        hoax(frank);
        floxConverter.bulkUpdateUserData(users, fxtlPoints, floxStakeUnits);

        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();

        vm.expectEmit(true, false, false, true);
        emit DistributionAllocated(alice, uint256(100e18 * 50 * 7 days) / ((365 days * 250)));
        vm.expectEmit(true, false, false, true);
        emit DistributionAllocated(bob, uint256(100e18 * 100 * 7 days) / ((365 days * 250)));
        hoax(frank);
        floxConverter.distributeFrax(usersToDistribute);

        assertApproxEqAbs(floxConverter.remainingFraxAvailable(), 100e18 - (uint256(100e18 * 150 * 7 days * 2) / ((365 days * 250))), 2);
        assertApproxEqAbs(address(floxConverter).balance, 100e18 - (uint256(100e18 * 150 * 7 days * 2) / ((365 days * 250))), 2);

        assertEq(floxConverter.totalFxtlPointsRedeemed(), 10e18);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, alice);

        (userData.totalFxtlPointsRedeemed, userData.totalFraxReceived) = floxConverter.userStats(alice);

        assertEq(epochUserData.fxtlPointsRedeemed, 2e18);
        assertApproxEqAbs(epochUserData.fraxReceived, uint256(100e18 * 50 * 7 days) / ((365 days * 250)), 2);
        assertEq(epochUserData.floxStakeUnits, 50);
        assertEq(userData.totalFxtlPointsRedeemed, 4e18);
        assertApproxEqAbs(userData.totalFraxReceived, uint256(100e18 * 50 * 7 days * 2) / ((365 days * 250)), 2);

        (epochUserData.fxtlPointsRedeemed, epochUserData.fraxReceived, epochUserData.floxStakeUnits) = floxConverter.redemptionEpochUserData(1, bob);

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

        vm.mockCall(address(floxConverter.FXTL_POINTS()), abi.encodeWithSignature("balanceOf(address)", alice), abi.encode(100e18));

        uint256 availableFxtlPoints = floxConverter.totalEligibleFxtlPointsByUser(alice);
        uint256 redeemedPoints;
        (redeemedPoints,) = floxConverter.userStats(alice);
        assertEq(availableFxtlPoints, floxConverter.FXTL_POINTS().balanceOf(alice) - redeemedPoints);
    }

    function test_finalizeRedemptionEpoch() public {
        floxCapSetup();

        assertEq(floxConverter.latestAllocatedDistributionEpoch(), 0);

        RedemptionEpoch memory redemptionEpoch;

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,,,,) = floxConverter.redemptionEpochs(1);

        assertFalse(redemptionEpoch.initiated);
        assertFalse(redemptionEpoch.populated);
        assertFalse(redemptionEpoch.finalized);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxConverter.finalizeRedemptionEpoch();

        vm.expectRevert(EpochNotInitiated.selector);
        hoax(frank);
        floxConverter.finalizeRedemptionEpoch();

        hoax(frank);
        floxConverter.initiateRedemptionEpoch(1000);

        vm.expectRevert(EpochNotPopulated.selector);
        hoax(frank);
        floxConverter.finalizeRedemptionEpoch();

        hoax(frank);
        floxConverter.markRedemptionEpochAsPopulated();

        vm.expectEmit(false, false, false, true);
        emit RedemptionEpochFinalized(1);
        hoax(frank);
        floxConverter.finalizeRedemptionEpoch();

        (redemptionEpoch.initiated, redemptionEpoch.populated, redemptionEpoch.finalized,,,,,) = floxConverter.redemptionEpochs(1);

        assertTrue(redemptionEpoch.initiated);
        assertTrue(redemptionEpoch.populated);
        assertTrue(redemptionEpoch.finalized);
        assertEq(floxConverter.latestAllocatedDistributionEpoch(), 1);

        hoax(frank);
        floxConverter.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxConverter.finalizeRedemptionEpoch();
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

    function test_recoverFrax() public {
        floxCapSetup();
        deal(address(floxConverter), 100e18);

        uint256 thisBalance = address(this).balance;
        uint256 contractBalance = address(floxConverter).balance;

        vm.expectEmit(false, false, false, true);
        emit RecoveredFrax(contractBalance / 2);
        floxConverter.recoverFrax(contractBalance / 2);

        assertEq(address(this).balance, thisBalance + (contractBalance / 2));
        assertEq(address(floxConverter).balance, contractBalance / 2);

        vm.expectRevert(OnlyOwner.selector);
        hoax(frank);
        floxConverter.recoverFrax(contractBalance / 2);

        vm.expectRevert(TransferFailed.selector);
        floxConverter.recoverFrax(contractBalance);
    }

    receive() external payable {
        // Allow the tested contract to send FRAX to this test contract
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
