// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FloxCapacitor, IFloxCapacitorErrors, IFloxCapacitorEvents } from "src/contracts/VestedFXS-and-Flox/Flox/FloxCapacitor.sol";
import { OwnedUpgradeable } from "src/contracts/VestedFXS-and-Flox/Flox/OwnedUpgradeable.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_FloxCapacitor is BaseTestVeFXS, IFloxCapacitorErrors, IFloxCapacitorEvents, OwnedUpgradeable {
    function floxCapSetup() public {
        console.log("defaultSetup() called");
        super.defaultSetup();

        // Mint FXS to the test users
        token.mint(alice, 100e18);
        token.mint(bob, 100e18);

        // Set frank as the Flox contributor
        floxCap.addFloxContributor(frank);
    }

    function test_commitTransferOwnership() public {
        floxCapSetup();

        vm.expectEmit(true, false, false, true);
        emit OwnerNominated(bob);
        floxCap.nominateNewOwner(bob);
        assertEq(floxCap.nominatedOwner(), bob);

        vm.expectRevert(OnlyOwner.selector);
        hoax(bob);
        floxCap.nominateNewOwner(bob);
    }

    function test_acceptOwnership() public {
        floxCapSetup();

        floxCap.nominateNewOwner(bob);
        vm.expectEmit(true, true, false, true);
        emit OwnerChanged(address(this), bob);
        hoax(bob);
        floxCap.acceptOwnership();
        assertEq(floxCap.owner(), bob);

        vm.expectRevert(InvalidOwnershipAcceptance.selector);
        hoax(alice);
        floxCap.acceptOwnership();

        vm.expectRevert(OwnerCannotBeZeroAddress.selector);
        hoax(bob);
        floxCap.nominateNewOwner(address(0));
    }

    function test_stopOperation() public {
        floxCapSetup();

        assertFalse(floxCap.isPaused());

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(true, block.timestamp);
        hoax(frank);
        floxCap.stopOperation();
        assertTrue(floxCap.isPaused());

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxCap.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        hoax(frank);
        floxCap.stopOperation();
    }

    function test_restartOperation() public {
        floxCapSetup();

        assertFalse(floxCap.isPaused());

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(true, block.timestamp);
        hoax(frank);
        floxCap.stopOperation();
        assertTrue(floxCap.isPaused());

        vm.expectRevert(OnlyOwner.selector);
        hoax(frank);
        floxCap.restartOperation();

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(false, block.timestamp);
        floxCap.restartOperation();

        vm.expectRevert(ContractOperational.selector);
        floxCap.restartOperation();
    }

    function test_updateVeFraxDivisor() public {
        floxCapSetup();

        assertEq(floxCap.veFraxDivisor(), 4);

        vm.expectEmit(false, false, false, true);
        emit VeFRAXDivisorUpdated(4, 2);
        hoax(frank);
        floxCap.updateVeFraxDivisor(2);

        assertEq(floxCap.veFraxDivisor(), 2);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxCap.updateVeFraxDivisor(2);

        vm.expectRevert(InvalidVeFRAXDivisor.selector);
        hoax(frank);
        floxCap.updateVeFraxDivisor(0);
    }

    function test_enableVeFraxUse() public {
        floxCapSetup();

        assertTrue(floxCap.useVeFRAX());

        vm.expectRevert(AlreadyUsingVeFRAX.selector);
        hoax(frank);
        floxCap.enableVeFraxUse();

        vm.expectEmit(false, false, false, true);
        emit VeFraxUseDisabled();
        hoax(frank);
        floxCap.disableVeFraxUse();

        assertFalse(floxCap.useVeFRAX());

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxCap.enableVeFraxUse();

        vm.expectEmit(false, false, false, true);
        emit VeFraxUseEnabled();
        hoax(frank);
        floxCap.enableVeFraxUse();

        assertTrue(floxCap.useVeFRAX());
    }

    function test_disableVeFraxUse() public {
        floxCapSetup();

        assertTrue(floxCap.useVeFRAX());

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxCap.disableVeFraxUse();

        vm.expectEmit(false, false, false, true);
        emit VeFraxUseDisabled();
        hoax(frank);
        floxCap.disableVeFraxUse();

        assertFalse(floxCap.useVeFRAX());

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxCap.disableVeFraxUse();

        vm.expectRevert(NotUsingVeFRAX.selector);
        hoax(frank);
        floxCap.disableVeFraxUse();
    }

    function test_addFloxContributor() public {
        floxCapSetup();

        assertFalse(floxCap.isFloxContributor(bob));

        vm.expectEmit(false, false, false, true);
        emit FloxContributorAdded(bob);
        floxCap.addFloxContributor(bob);
        assertTrue(floxCap.isFloxContributor(bob));

        vm.expectRevert(OnlyOwner.selector);
        hoax(bob);
        floxCap.addFloxContributor(alice);

        vm.expectRevert(AlreadyFloxContributor.selector);
        floxCap.addFloxContributor(bob);
    }

    function test_removeFloxContributor() public {
        floxCapSetup();

        floxCap.addFloxContributor(bob);
        assertTrue(floxCap.isFloxContributor(bob));

        vm.expectEmit(false, false, false, true);
        emit FloxContributorRemoved(bob);
        floxCap.removeFloxContributor(bob);
        assertFalse(floxCap.isFloxContributor(bob));

        vm.expectRevert(OnlyOwner.selector);
        hoax(frank);
        floxCap.removeFloxContributor(frank);

        vm.expectRevert(NotFloxContributor.selector);
        floxCap.removeFloxContributor(bob);
    }

    function test_balanceOf() public {
        floxCapSetup();

        assertEq(floxCap.balanceOf(alice), 0);
        assertEq(floxCap.balanceOf(bob), 0);

        hoax(alice);
        token.approve(address(fraxStaker), 100e18);
        hoax(alice);
        fraxStaker.stakeFrax{ value: 50e18 }();

        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 0);

        hoax(bob);
        token.approve(address(fraxStaker), 100e18);
        hoax(bob);
        fraxStaker.stakeFrax{ value: 25e18 }();
        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);

        uint8 divisor = floxCap.veFraxDivisor();

        vm.mockCall(address(veFXSAggregator), abi.encodeWithSelector(VeFXSAggregator.balanceOf.selector, address(bob)), abi.encode(100e18));

        vm.mockCall(address(veFXSAggregator), abi.encodeWithSelector(VeFXSAggregator.balanceOf.selector, address(alice)), abi.encode(400e18));

        assertEq(floxCap.balanceOf(alice), 50e18 + (400e18 / divisor));
        assertEq(floxCap.balanceOf(bob), 25e18 + (100e18 / divisor));

        hoax(frank);
        floxCap.disableVeFraxUse();
        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);
    }

    function test_delegate() public {
        floxCapSetup();

        hoax(alice);
        fraxStaker.stakeFrax{ value: 50e18 }();
        hoax(bob);
        fraxStaker.stakeFrax{ value: 25e18 }();

        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);

        vm.expectRevert(CannotDelegateToSelf.selector);
        hoax(frank);
        floxCap.delegate(alice, alice);

        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(alice, bob);
        hoax(frank);
        floxCap.delegate(alice, bob);

        assertEq(floxCap.delegations(alice), bob);
        assertEq(floxCap.incomingDelegationsCount(bob), 1);
        assertEq(floxCap.incomingDelegations(bob, 0), alice);
        assertEq(floxCap.balanceOf(alice), 0);
        assertEq(floxCap.balanceOf(bob), 75e18);

        vm.expectRevert(AlreadyDelegated.selector);
        hoax(frank);
        floxCap.delegate(alice, frank);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(alice);
        floxCap.delegate(alice, frank);

        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(bob, frank);
        hoax(frank);
        floxCap.delegate(bob, frank);

        assertEq(floxCap.delegations(alice), bob);
        assertEq(floxCap.incomingDelegationsCount(bob), 1);
        assertEq(floxCap.incomingDelegations(bob, 0), alice);
        assertEq(floxCap.balanceOf(alice), 0);
        assertEq(floxCap.balanceOf(bob), 50e18);
        assertEq(floxCap.delegations(bob), frank);
        assertEq(floxCap.incomingDelegationsCount(frank), 1);
        assertEq(floxCap.incomingDelegations(frank, 0), bob);
        assertEq(floxCap.balanceOf(frank), 25e18);
    }

    function test_bulkDelegate() public {
        floxCapSetup();

        hoax(alice);
        fraxStaker.stakeFrax{ value: 50e18 }();
        hoax(bob);
        fraxStaker.stakeFrax{ value: 25e18 }();
        hoax(claire);
        fraxStaker.stakeFrax{ value: 10e18 }();
        hoax(dave);
        fraxStaker.stakeFrax{ value: 15e18 }();

        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);
        assertEq(floxCap.balanceOf(claire), 10e18);
        assertEq(floxCap.balanceOf(dave), 15e18);

        address[] memory delegators = new address[](3);
        delegators[0] = alice;
        delegators[1] = claire;
        delegators[2] = bob;

        address[] memory delegatees = new address[](3);
        delegatees[0] = bob;
        delegatees[1] = dave;
        delegatees[2] = dave;

        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(alice, bob);
        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(claire, dave);
        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(bob, dave);
        hoax(frank);
        floxCap.bulkDelegate(delegators, delegatees);

        assertEq(floxCap.delegations(alice), bob);
        assertEq(floxCap.incomingDelegationsCount(bob), 1);
        assertEq(floxCap.incomingDelegations(bob, 0), alice);
        assertEq(floxCap.balanceOf(alice), 0);
        assertEq(floxCap.balanceOf(bob), 50e18);

        assertEq(floxCap.delegations(claire), dave);
        assertEq(floxCap.incomingDelegationsCount(dave), 2);
        assertEq(floxCap.incomingDelegations(dave, 0), claire);
        assertEq(floxCap.balanceOf(claire), 0);
        assertEq(floxCap.balanceOf(dave), 50e18);

        assertEq(floxCap.delegations(bob), dave);
        assertEq(floxCap.incomingDelegationsCount(dave), 2);
        assertEq(floxCap.incomingDelegations(dave, 1), bob);
        assertEq(floxCap.balanceOf(bob), 50e18);
        assertEq(floxCap.balanceOf(dave), 50e18);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(alice);
        floxCap.bulkDelegate(delegators, delegatees);

        vm.expectRevert(ArrayLengthMismatch.selector);
        hoax(frank);
        floxCap.bulkDelegate(delegators, new address[](2));

        vm.expectRevert(AlreadyDelegated.selector);
        hoax(frank);
        floxCap.bulkDelegate(delegators, delegatees);

        delegators[0] = bob;
        vm.expectRevert(CannotDelegateToSelf.selector);
        hoax(frank);
        floxCap.bulkDelegate(delegators, delegatees);
    }

    function test_revokeDelegation() public {
        floxCapSetup();

        hoax(alice);
        fraxStaker.stakeFrax{ value: 50e18 }();
        hoax(bob);
        fraxStaker.stakeFrax{ value: 25e18 }();

        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);

        hoax(frank);
        floxCap.delegate(alice, bob);
        hoax(frank);
        floxCap.delegate(claire, bob);
        hoax(frank);
        floxCap.delegate(frank, bob);

        assertEq(floxCap.delegations(alice), bob);
        assertEq(floxCap.incomingDelegationsCount(bob), 3);
        assertEq(floxCap.incomingDelegations(bob, 0), alice);
        assertEq(floxCap.balanceOf(alice), 0);
        assertEq(floxCap.balanceOf(bob), 75e18);

        vm.expectRevert(NoActiveDelegations.selector);
        hoax(frank);
        floxCap.revokeDelegation(bob);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(bob);
        floxCap.revokeDelegation(bob);

        vm.expectEmit(true, true, false, true);
        emit DelegationRemoved(alice, bob);
        hoax(frank);
        floxCap.revokeDelegation(alice);

        assertEq(floxCap.delegations(alice), address(0));
        assertEq(floxCap.incomingDelegationsCount(bob), 2);
        assertEq(floxCap.incomingDelegations(bob, 0), frank);
        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);
    }

    function test_bulkRevokeDelegation() public {
        floxCapSetup();

        hoax(alice);
        fraxStaker.stakeFrax{ value: 50e18 }();
        hoax(bob);
        fraxStaker.stakeFrax{ value: 25e18 }();
        hoax(claire);
        fraxStaker.stakeFrax{ value: 10e18 }();
        hoax(dave);
        fraxStaker.stakeFrax{ value: 15e18 }();

        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);
        assertEq(floxCap.balanceOf(claire), 10e18);
        assertEq(floxCap.balanceOf(dave), 15e18);

        address[] memory delegators = new address[](3);
        delegators[0] = alice;
        delegators[1] = claire;
        delegators[2] = bob;

        address[] memory delegatees = new address[](3);
        delegatees[0] = bob;
        delegatees[1] = dave;
        delegatees[2] = dave;

        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(alice, bob);
        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(claire, dave);
        vm.expectEmit(true, true, false, true);
        emit DelegationAdded(bob, dave);
        hoax(frank);
        floxCap.bulkDelegate(delegators, delegatees);

        assertEq(floxCap.delegations(alice), bob);
        assertEq(floxCap.incomingDelegationsCount(bob), 1);
        assertEq(floxCap.incomingDelegations(bob, 0), alice);
        assertEq(floxCap.balanceOf(alice), 0);
        assertEq(floxCap.balanceOf(bob), 50e18);

        assertEq(floxCap.delegations(claire), dave);
        assertEq(floxCap.incomingDelegationsCount(dave), 2);
        assertEq(floxCap.incomingDelegations(dave, 0), claire);
        assertEq(floxCap.balanceOf(claire), 0);
        assertEq(floxCap.balanceOf(dave), 50e18);

        assertEq(floxCap.delegations(bob), dave);
        assertEq(floxCap.incomingDelegationsCount(dave), 2);
        assertEq(floxCap.incomingDelegations(dave, 1), bob);
        assertEq(floxCap.balanceOf(bob), 50e18);
        assertEq(floxCap.balanceOf(dave), 50e18);

        vm.expectRevert(NotFloxContributor.selector);
        hoax(alice);
        floxCap.bulkRevokeDelegation(delegators);

        vm.expectEmit(true, true, false, true);
        emit DelegationRemoved(alice, bob);
        vm.expectEmit(true, true, false, true);
        emit DelegationRemoved(claire, dave);
        vm.expectEmit(true, true, false, true);
        emit DelegationRemoved(bob, dave);
        hoax(frank);
        floxCap.bulkRevokeDelegation(delegators);

        assertEq(floxCap.delegations(alice), address(0));
        assertEq(floxCap.incomingDelegationsCount(bob), 0);
        assertEq(floxCap.incomingDelegations(bob, 0), address(0));
        assertEq(floxCap.balanceOf(alice), 50e18);
        assertEq(floxCap.balanceOf(bob), 25e18);

        assertEq(floxCap.delegations(claire), address(0));
        assertEq(floxCap.incomingDelegationsCount(dave), 0);
        assertEq(floxCap.incomingDelegations(dave, 0), address(0));
        assertEq(floxCap.balanceOf(claire), 10e18);
        assertEq(floxCap.balanceOf(dave), 15e18);

        assertEq(floxCap.delegations(bob), address(0));
        assertEq(floxCap.incomingDelegationsCount(dave), 0);
        assertEq(floxCap.incomingDelegations(dave, 1), address(0));
        assertEq(floxCap.balanceOf(bob), 25e18);
        assertEq(floxCap.balanceOf(dave), 15e18);

        vm.expectRevert(NoActiveDelegations.selector);
        hoax(frank);
        floxCap.bulkRevokeDelegation(delegators);
    }
}
