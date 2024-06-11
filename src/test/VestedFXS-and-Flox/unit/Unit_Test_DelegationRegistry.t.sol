// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { DelegationRegistry } from "src/contracts/VestedFXS-and-Flox/Flox/DelegationRegistry.sol";
import { OwnedV2 } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2.sol";
import { RegistryDelegate } from "src/test/VestedFXS-and-Flox/helpers/RegistryDelegate.sol";

contract Unit_Test_DelegationRegistry is BaseTestVeFXS {
    using stdStorage for StdStorage;

    DelegationRegistry public registry;

    event DelegationUpdated(address indexed delegator, address indexed previousDelegatee, address indexed newDelegatee);
    event FraxContributorAdded(address indexed contributor);
    event FraxContributorRemoved(address indexed contributor);

    function setUp() public {
        defaultSetup();

        registry = new DelegationRegistry();
    }

    function test_SetDelegationForSelf() public {
        assertEq(registry.delegationsOf(bob), bob, "Delegation already set");
        assertEq(registry.delegationsOf(alice), alice, "Delegation already set");
        assertFalse(registry.selfManagingDelegations(bob));
        assertFalse(registry.selfManagingDelegations(alice));

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(bob, address(0), alice);
        hoax(bob);
        registry.setDelegationForSelf(alice);

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, address(0), bob);
        hoax(alice);
        registry.setDelegationForSelf(bob);

        assertEq(registry.delegationsOf(bob), alice, "Delegation not set");
        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");
        assertTrue(registry.selfManagingDelegations(bob));
        assertTrue(registry.selfManagingDelegations(alice));

        hoax(bob);
        registry.disableDelegationManagement();
        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.setDelegationForSelf(alice);
    }

    function test_RemoveDelegationForSelf() public {
        hoax(bob);
        registry.setDelegationForSelf(alice);
        hoax(alice);
        registry.setDelegationForSelf(bob);
        assertEq(registry.delegationsOf(bob), alice, "Delegation not set");
        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(bob, alice, address(0));
        hoax(bob);
        registry.removeDelegationForSelf();

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, bob, address(0));
        hoax(alice);
        registry.removeDelegationForSelf();

        assertEq(registry.delegationsOf(bob), bob, "Delegation not removed");
        assertEq(registry.delegationsOf(alice), alice, "Delegation not removed");

        hoax(bob);
        registry.disableDelegationManagement();
        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.removeDelegationForSelf();
    }

    function test_DisableSelfManagingDelegations() public {
        hoax(bob);
        registry.setDelegationForSelf(alice);

        assertTrue(registry.selfManagingDelegations(bob));

        hoax(bob);
        registry.disableSelfManagingDelegations();

        assertFalse(registry.selfManagingDelegations(bob));

        vm.expectRevert(DelegationRegistry.SelfManagingDelegationsDisabled.selector);
        hoax(bob);
        registry.disableSelfManagingDelegations();
    }

    function test_DisableDelegationManagement() public {
        assertFalse(registry.delegationManagementDisabled(bob));

        hoax(bob);
        registry.disableDelegationManagement();

        assertTrue(registry.delegationManagementDisabled(bob));

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.disableDelegationManagement();

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.setDelegationForSelf(alice);
    }

    function test_SetDelegation() public {
        assertEq(registry.delegationsOf(bob), bob, "Delegation already set");
        assertEq(registry.delegationsOf(alice), alice, "Delegation already set");

        registry.addFraxContributor(bob);

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, address(0), bob);
        hoax(bob);
        registry.setDelegation(alice, bob);

        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");

        vm.expectRevert(DelegationRegistry.NotFraxContributorOrDelegatee.selector);
        hoax(alice);
        registry.setDelegation(bob, alice);

        registry.removeFraxContributor(bob);

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, bob, alice);
        hoax(bob);
        registry.setDelegation(alice, alice);

        assertEq(registry.delegationsOf(alice), alice, "Delegation not set");

        vm.expectRevert(DelegationRegistry.NotFraxContributorOrDelegatee.selector);
        hoax(bob);
        registry.setDelegation(alice, bob);

        assertFalse(registry.selfManagingDelegations(alice));

        hoax(alice);
        registry.removeDelegationForSelf();

        assertTrue(registry.selfManagingDelegations(alice));

        registry.addFraxContributor(bob);
        vm.expectRevert(DelegationRegistry.SelfManagingDelegations.selector);
        hoax(bob);
        registry.setDelegation(alice, bob);

        hoax(alice);
        registry.disableSelfManagingDelegations();
        hoax(alice);
        registry.disableDelegationManagement();

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.setDelegation(alice, bob);
    }

    function test_RemoveDelegation() public {
        assertEq(registry.delegationsOf(bob), bob, "Delegation already set");
        assertEq(registry.delegationsOf(alice), alice, "Delegation already set");

        vm.expectRevert(DelegationRegistry.NotFraxContributorOrDelegatee.selector);
        hoax(bob);
        registry.removeDelegation(alice);

        registry.addFraxContributor(bob);
        hoax(bob);
        registry.setDelegation(alice, bob);

        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, bob, address(0));
        hoax(bob);
        registry.removeDelegation(alice);

        assertEq(registry.delegationsOf(alice), alice, "Delegation not removed");

        hoax(bob);
        registry.setDelegation(alice, bob);

        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");

        registry.removeFraxContributor(bob);

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, bob, address(0));
        hoax(bob);
        registry.removeDelegation(alice);

        assertEq(registry.delegationsOf(alice), alice, "Delegation not removed");
        assertFalse(registry.selfManagingDelegations(alice));

        hoax(alice);
        registry.setDelegationForSelf(bob);

        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");
        assertTrue(registry.selfManagingDelegations(alice));

        vm.expectRevert(DelegationRegistry.SelfManagingDelegations.selector);
        hoax(bob);
        registry.removeDelegation(alice);

        hoax(alice);
        registry.disableSelfManagingDelegations();
        hoax(alice);
        registry.disableDelegationManagement();

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.removeDelegation(alice);
    }

    function test_BulkSetDelegationsAsFraxContributor() public {
        address[] memory delegators = new address[](2);
        address[] memory delegatees = new address[](2);
        delegators[0] = bob;
        delegators[1] = alice;
        delegatees[0] = alice;
        delegatees[1] = bob;

        vm.expectRevert(DelegationRegistry.NotFraxContributor.selector);
        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        registry.addFraxContributor(bob);

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(bob, address(0), alice);
        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, address(0), bob);
        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        assertEq(registry.delegationsOf(bob), alice, "Delegation not set");
        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");
        assertFalse(registry.selfManagingDelegations(bob));
        assertFalse(registry.selfManagingDelegations(alice));

        vm.expectRevert(DelegationRegistry.ArrayLengthMismatch.selector);
        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, new address[](1));

        hoax(alice);
        registry.removeDelegationForSelf();

        vm.expectRevert(DelegationRegistry.SelfManagingDelegations.selector);
        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        hoax(alice);
        registry.disableSelfManagingDelegations();
        hoax(alice);
        registry.disableDelegationManagement();

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);
    }

    function test_BulkRemoveDelegationsAsFraxContributor() public {
        address[] memory delegators = new address[](2);
        address[] memory delegatees = new address[](2);
        delegators[0] = bob;
        delegators[1] = alice;
        delegatees[0] = alice;
        delegatees[1] = bob;

        vm.expectRevert(DelegationRegistry.NotFraxContributor.selector);
        hoax(bob);
        registry.bulkRemoveDelegationsAsFraxContributor(delegators);

        registry.addFraxContributor(bob);

        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        assertEq(registry.delegationsOf(bob), alice, "Delegation not set");
        assertEq(registry.delegationsOf(alice), bob, "Delegation not set");

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(bob, alice, address(0));
        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, bob, address(0));
        hoax(bob);
        registry.bulkRemoveDelegationsAsFraxContributor(delegators);

        assertEq(registry.delegationsOf(bob), bob, "Delegation not removed");
        assertEq(registry.delegationsOf(alice), alice, "Delegation not removed");

        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        assertFalse(registry.selfManagingDelegations(alice));

        hoax(alice);
        registry.removeDelegationForSelf();

        assertTrue(registry.selfManagingDelegations(alice));

        vm.expectRevert(DelegationRegistry.SelfManagingDelegations.selector);
        hoax(bob);
        registry.bulkRemoveDelegationsAsFraxContributor(delegators);

        hoax(alice);
        registry.disableSelfManagingDelegations();
        hoax(alice);
        registry.disableDelegationManagement();

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.bulkRemoveDelegationsAsFraxContributor(delegators);
    }

    function test_BulkSetDelegationsAsDelegatee() public {
        address[] memory delegators = new address[](2);
        address[] memory delegatees = new address[](2);
        delegators[0] = bob;
        delegators[1] = alice;
        delegatees[0] = address(this);
        delegatees[1] = address(this);

        registry.addFraxContributor(bob);

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(bob, address(0), address(this));
        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, address(0), address(this));
        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        assertEq(registry.delegationsOf(bob), address(this), "Delegation not set");
        assertEq(registry.delegationsOf(alice), address(this), "Delegation not set");
        assertFalse(registry.selfManagingDelegations(bob));
        assertFalse(registry.selfManagingDelegations(alice));

        vm.expectRevert(DelegationRegistry.ArrayLengthMismatch.selector);
        registry.bulkSetDelegationsAsDelegatee(delegators, new address[](1));

        vm.expectRevert(DelegationRegistry.NotDelegatee.selector);
        hoax(bob);
        registry.bulkSetDelegationsAsDelegatee(delegators, delegatees);

        delegatees[0] = alice;
        delegatees[1] = bob;

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(bob, address(this), alice);
        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, address(this), bob);
        registry.bulkSetDelegationsAsDelegatee(delegators, delegatees);

        assertEq(registry.delegationsOf(bob), alice, "Delegation not updated");
        assertEq(registry.delegationsOf(alice), bob, "Delegation not updated");
        assertFalse(registry.selfManagingDelegations(bob));
        assertFalse(registry.selfManagingDelegations(alice));

        hoax(alice);
        registry.removeDelegationForSelf();

        delegators[0] = alice;
        vm.expectRevert(DelegationRegistry.SelfManagingDelegations.selector);
        hoax(bob);
        registry.bulkSetDelegationsAsDelegatee(delegators, delegatees);

        hoax(alice);
        registry.disableSelfManagingDelegations();
        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);
        hoax(alice);
        registry.disableDelegationManagement();

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        hoax(bob);
        registry.bulkSetDelegationsAsDelegatee(delegators, delegatees);
    }

    function test_BulkRemoveDelegationsAsDelegatee() public {
        address[] memory delegators = new address[](2);
        address[] memory delegatees = new address[](2);
        delegators[0] = bob;
        delegators[1] = alice;
        delegatees[0] = address(this);
        delegatees[1] = address(this);

        registry.addFraxContributor(bob);

        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        assertEq(registry.delegationsOf(bob), address(this), "Delegation not set");
        assertEq(registry.delegationsOf(alice), address(this), "Delegation not set");

        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(bob, address(this), address(0));
        vm.expectEmit(true, true, true, true);
        emit DelegationUpdated(alice, address(this), address(0));
        registry.bulkRemoveDelegationsAsDelegatee(delegators);

        assertEq(registry.delegationsOf(bob), bob, "Delegation not removed");
        assertEq(registry.delegationsOf(alice), alice, "Delegation not removed");

        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        hoax(alice);
        registry.removeDelegationForSelf();

        delegators[0] = alice;
        vm.expectRevert(DelegationRegistry.SelfManagingDelegations.selector);
        hoax(bob);
        registry.bulkRemoveDelegationsAsDelegatee(delegators);

        hoax(alice);
        registry.disableSelfManagingDelegations();

        vm.expectRevert(DelegationRegistry.NotDelegatee.selector);
        hoax(bob);
        registry.bulkRemoveDelegationsAsDelegatee(delegators);

        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);
        hoax(alice);
        registry.disableDelegationManagement();

        vm.expectRevert(DelegationRegistry.DelegationManagementDisabled.selector);
        registry.bulkRemoveDelegationsAsDelegatee(delegators);
    }

    function test_AddFraxContributor() public {
        assertFalse(registry.isFraxContributor(bob));

        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        hoax(alice);
        registry.addFraxContributor(bob);

        vm.expectEmit(true, false, false, true);
        emit FraxContributorAdded(bob);
        registry.addFraxContributor(bob);

        assertTrue(registry.isFraxContributor(bob));

        vm.expectRevert(DelegationRegistry.AlreadyFraxContributor.selector);
        registry.addFraxContributor(bob);
    }

    function test_RemoveFraxContributor() public {
        registry.addFraxContributor(bob);
        assertTrue(registry.isFraxContributor(bob));

        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        hoax(alice);
        registry.removeFraxContributor(bob);

        vm.expectEmit(true, false, false, true);
        emit FraxContributorRemoved(bob);
        registry.removeFraxContributor(bob);

        assertFalse(registry.isFraxContributor(bob));

        vm.expectRevert(DelegationRegistry.NotFraxContributor.selector);
        registry.removeFraxContributor(bob);
    }

    function test_ReenableDelegationManagement() public {
        hoax(bob);
        registry.disableDelegationManagement();
        assertTrue(registry.delegationManagementDisabled(bob));

        registry.addFraxContributor(alice);
        hoax(alice);
        registry.reenableDelegationManagement(bob);

        assertFalse(registry.delegationManagementDisabled(bob));

        vm.expectRevert(DelegationRegistry.DelegationManagementEnabled.selector);
        hoax(alice);
        registry.reenableDelegationManagement(bob);
    }

    function test_DelegationsOf() public {
        assertEq(registry.delegationsOf(bob), bob, "Delegation already set");

        hoax(bob);
        registry.setDelegationForSelf(alice);

        assertEq(registry.delegationsOf(bob), alice, "Delegation not set");

        hoax(bob);
        registry.removeDelegationForSelf();

        assertEq(registry.delegationsOf(bob), bob, "Delegation not removed");
    }

    function test_BulkDelegationsOf() public {
        address[] memory delegators = new address[](2);
        delegators[0] = bob;
        delegators[1] = alice;
        address[] memory delegatees = new address[](2);
        delegatees[0] = alice;
        delegatees[1] = bob;

        registry.addFraxContributor(bob);

        address[] memory result = registry.bulkDelegationsOf(delegators);
        assertEq(result, delegators, "Delegations already set");

        hoax(bob);
        registry.bulkSetDelegationsAsFraxContributor(delegators, delegatees);

        result = registry.bulkDelegationsOf(delegators);

        assertEq(result, delegatees, "Delegation not set");

        hoax(bob);
        registry.bulkRemoveDelegationsAsFraxContributor(delegators);

        result = registry.bulkDelegationsOf(delegators);

        assertEq(result, delegators, "Delegation not removed");
    }

    function test_ConstructorDelegationWithoutInterface() public {
        RegistryDelegate delegate = new RegistryDelegate(address(registry), alice, false);

        assertEq(registry.delegationsOf(address(delegate)), alice, "Delegation not set");
        assertFalse(registry.selfManagingDelegations(address(delegate)));
        assertFalse(registry.delegationManagementDisabled(address(delegate)));
    }

    function test_ConstructorDelegationManagementDisableWithoutInterface() public {
        RegistryDelegate delegate = new RegistryDelegate(address(registry), alice, true);

        assertEq(registry.delegationsOf(address(delegate)), alice, "Delegation not set");
        assertFalse(registry.selfManagingDelegations(address(delegate)));
        assertTrue(registry.delegationManagementDisabled(address(delegate)));
    }
}
