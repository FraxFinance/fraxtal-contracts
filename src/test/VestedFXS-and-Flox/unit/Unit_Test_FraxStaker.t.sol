// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FraxStaker, FraxStakerStructs } from "src/contracts/VestedFXS-and-Flox/FraxStaker/FraxStaker.sol";
import { OwnedUpgradeable } from "src/contracts/VestedFXS-and-Flox/Flox/OwnedUpgradeable.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_FraxStaker is BaseTestVeFXS, FraxStakerStructs, OwnedUpgradeable {
    uint256 aliceBalance;
    uint256 bobBalance;
    uint256 frankBalance;
    uint256 claireBalance;

    function fraxStakerSetup() public {
        console.log("defaultSetup() called");
        super.defaultSetup();

        deal(alice, 250e18);
        deal(bob, 250e18);
        deal(frank, 250e18);
        deal(claire, 250e18);
        deal(fraxStaker.SLASHING_RECIPIENT(), 0);

        // Updates user balances in order to be able to validate balance changes
        aliceBalance = alice.balance;
        bobBalance = bob.balance;
        frankBalance = frank.balance;
        claireBalance = claire.balance;

        // Set frank as the Frax contributor
        fraxStaker.addFraxContributor(frank);
    }

    function test_commitTransferOwnership() public {
        fraxStakerSetup();

        vm.expectEmit(true, false, false, true);
        emit OwnerNominated(bob);
        fraxStaker.nominateNewOwner(bob);
        assertEq(fraxStaker.nominatedOwner(), bob);

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(bob);
        fraxStaker.nominateNewOwner(bob);
    }

    function test_acceptOwnership() public {
        fraxStakerSetup();

        fraxStaker.nominateNewOwner(bob);
        vm.expectEmit(true, true, false, true);
        emit OwnerChanged(address(this), bob);
        vm.prank(bob);
        fraxStaker.acceptOwnership();
        assertEq(fraxStaker.owner(), bob);

        vm.expectRevert(InvalidOwnershipAcceptance.selector);
        vm.prank(alice);
        fraxStaker.acceptOwnership();

        vm.expectRevert(OwnerCannotBeZeroAddress.selector);
        vm.prank(bob);
        fraxStaker.nominateNewOwner(address(0));
    }

    function test_stopOperation() public {
        fraxStakerSetup();

        assertFalse(fraxStaker.isPaused());

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(true, block.timestamp);
        vm.prank(frank);
        fraxStaker.stopOperation();
        assertTrue(fraxStaker.isPaused());

        vm.expectRevert(NotFraxContributor.selector);
        vm.prank(bob);
        fraxStaker.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        vm.prank(frank);
        fraxStaker.stopOperation();
    }

    function test_restartOperation() public {
        fraxStakerSetup();

        assertFalse(fraxStaker.isPaused());

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(true, block.timestamp);
        vm.prank(frank);
        fraxStaker.stopOperation();
        assertTrue(fraxStaker.isPaused());

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(frank);
        fraxStaker.restartOperation();

        vm.expectEmit(false, false, false, true);
        emit OperationPaused(false, block.timestamp);
        fraxStaker.restartOperation();

        vm.expectRevert(ContractOperational.selector);
        fraxStaker.restartOperation();
    }

    function test_updateWithdrawalCooldown() public {
        fraxStakerSetup();

        assertEq(fraxStaker.withdrawalCooldown(), 90 days);

        vm.expectEmit(false, false, false, true);
        emit WithdrawalCooldownUpdated(90 days, 42 days);
        fraxStaker.updateWithdrawalCooldown(42 days);

        assertEq(fraxStaker.withdrawalCooldown(), 42 days);

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(frank);
        fraxStaker.updateWithdrawalCooldown(42 days);
    }

    function test_addFraxContributor() public {
        fraxStakerSetup();

        assertFalse(fraxStaker.isFraxContributor(bob));

        vm.expectEmit(false, false, false, true);
        emit FraxContributorAdded(bob);
        fraxStaker.addFraxContributor(bob);
        assertTrue(fraxStaker.isFraxContributor(bob));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(bob);
        fraxStaker.addFraxContributor(alice);

        vm.expectRevert(AlreadyFraxContributor.selector);
        fraxStaker.addFraxContributor(bob);
    }

    function test_removeFraxContributor() public {
        fraxStakerSetup();

        fraxStaker.addFraxContributor(bob);
        assertTrue(fraxStaker.isFraxContributor(bob));

        vm.expectEmit(false, false, false, true);
        emit FraxContributorRemoved(bob);
        fraxStaker.removeFraxContributor(bob);
        assertFalse(fraxStaker.isFraxContributor(bob));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(frank);
        fraxStaker.removeFraxContributor(frank);

        vm.expectRevert(NotFraxContributor.selector);
        fraxStaker.removeFraxContributor(bob);
    }

    function test_stakeFrax() public {
        fraxStakerSetup();

        vm.expectRevert(InvalidStakeAmount.selector);
        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 0 }();

        vm.expectEmit(true, false, false, true);
        emit StakeUpdated(bob, 0, 50e18);
        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        Stake memory stakeEntry;
        (stakeEntry.amountStaked,,, stakeEntry.unlockTime,, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);
        assertEq(address(fraxStaker).balance, 50e18);

        vm.expectEmit(true, false, false, true);
        emit StakeUpdated(bob, 50e18, 75e18);
        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 25e18 }();

        (stakeEntry.amountStaked,,, stakeEntry.unlockTime,, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 75e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 75e18);
        assertApproxEqAbs(bob.balance, bobBalance - 75e18, 1e15);
        assertEq(address(fraxStaker).balance, 75e18);

        vm.prank(bob);
        fraxStaker.initiateWithdrawal();

        vm.expectRevert(WithdrawalInitiated.selector);
        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 10e18 }();

        vm.prank(frank);
        fraxStaker.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 10e18 }();
    }

    function test_initiateWithdrawal() public {
        fraxStakerSetup();

        vm.expectRevert(InvalidStakeAmount.selector);
        vm.prank(bob);
        fraxStaker.initiateWithdrawal();

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        address mockAddress;
        vm.startPrank(bob);
        for (uint8 i; i < 255;) {
            mockAddress = address(uint160(i + 1));

            fraxStaker.delegateStake(mockAddress, 1e14);

            unchecked {
                ++i;
            }
        }
        vm.stopPrank();

        Stake memory stakeEntry;
        (stakeEntry.amountStaked,,, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 255);
        assertFalse(stakeEntry.initiatedWithdrawal);

        vm.expectEmit(true, false, false, true);
        emit StakeWithdrawalInitiated(bob, 50e18, block.timestamp + 90 days);
        vm.prank(bob);
        fraxStaker.initiateWithdrawal();

        (stakeEntry.amountStaked,,, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.unlockTime, block.timestamp + 90 days);
        assertEq(stakeEntry.numberOfDelegations, 0);
        assertTrue(stakeEntry.initiatedWithdrawal);

        vm.expectRevert(WithdrawalInitiated.selector);
        vm.prank(bob);
        fraxStaker.initiateWithdrawal();

        vm.prank(frank);
        fraxStaker.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        vm.prank(bob);
        fraxStaker.initiateWithdrawal();
    }

    function test_withdrawStake() public {
        fraxStakerSetup();

        vm.expectRevert(WithdrawalNotInitiated.selector);
        vm.prank(bob);
        fraxStaker.withdrawStake();

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        Stake memory stakeEntry;
        (stakeEntry.amountStaked,,, stakeEntry.unlockTime,, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertFalse(stakeEntry.initiatedWithdrawal);

        vm.expectEmit(true, false, false, true);
        emit StakeWithdrawalInitiated(bob, 50e18, block.timestamp + 90 days);
        vm.prank(bob);
        fraxStaker.initiateWithdrawal();

        (stakeEntry.amountStaked,,, stakeEntry.unlockTime,, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.unlockTime, block.timestamp + 90 days);
        assertTrue(stakeEntry.initiatedWithdrawal);

        vm.expectRevert(WithdrawalNotAvailable.selector);
        vm.prank(bob);
        fraxStaker.withdrawStake();

        skip(90 days);
        vm.expectEmit(true, false, false, true);
        emit StakeUpdated(bob, 50e18, 0);
        vm.prank(bob);
        fraxStaker.withdrawStake();

        (stakeEntry.amountStaked,,, stakeEntry.unlockTime,, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 0);
        assertEq(stakeEntry.unlockTime, 0);
        assertFalse(stakeEntry.initiatedWithdrawal);

        assertEq(fraxStaker.balanceOf(bob), 0);
        assertApproxEqAbs(bob.balance, bobBalance, 1e15);
        assertEq(address(fraxStaker).balance, 0);

        vm.prank(frank);
        fraxStaker.stopOperation();
        vm.expectRevert(ContractPaused.selector);
        vm.prank(bob);
        fraxStaker.withdrawStake();
    }

    function test_addFraxSentinel() public {
        fraxStakerSetup();

        assertFalse(fraxStaker.isFraxSentinel(bob));

        vm.expectEmit(true, false, false, true);
        emit FraxSentinelAdded(bob);
        fraxStaker.addFraxSentinel(bob);
        assertTrue(fraxStaker.isFraxSentinel(bob));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(bob);
        fraxStaker.addFraxSentinel(alice);

        vm.expectRevert(AlreadyFraxSentinel.selector);
        fraxStaker.addFraxSentinel(bob);
    }

    function test_removeFraxSentinel() public {
        fraxStakerSetup();

        fraxStaker.addFraxSentinel(bob);
        assertTrue(fraxStaker.isFraxSentinel(bob));

        vm.expectEmit(true, false, false, true);
        emit FraxSentinelRemoved(bob);
        fraxStaker.removeFraxSentinel(bob);
        assertFalse(fraxStaker.isFraxSentinel(bob));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(frank);
        fraxStaker.removeFraxSentinel(frank);

        vm.expectRevert(NotFraxSentinel.selector);
        fraxStaker.removeFraxSentinel(bob);
    }

    function test_proposeSlashingRecipientUpdate() public {
        fraxStakerSetup();

        assertEq(fraxStaker.SLASHING_RECIPIENT(), address(0xdead));
        assertEq(fraxStaker.proposedSlashingRecipient(), address(0));
        assertEq(fraxStaker.proposedSlashingRecipientTimestamp(), 0);

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(frank);
        fraxStaker.proposeSlashingRecipientUpdate(bob);

        vm.expectRevert(AlreadySlashingRecipient.selector);
        fraxStaker.proposeSlashingRecipientUpdate(address(0xdead));

        vm.expectEmit(true, true, false, true);
        emit SlashingRecipientUpdateProposed(address(0xdead), bob);
        fraxStaker.proposeSlashingRecipientUpdate(bob);

        assertEq(fraxStaker.SLASHING_RECIPIENT(), address(0xdead));
        assertEq(fraxStaker.proposedSlashingRecipient(), bob);
        assertEq(fraxStaker.proposedSlashingRecipientTimestamp(), block.timestamp + 7 days);
    }

    function test_acceptSlashingRecipientUpdate() public {
        fraxStakerSetup();

        assertEq(fraxStaker.SLASHING_RECIPIENT(), address(0xdead));
        assertEq(fraxStaker.proposedSlashingRecipient(), address(0));
        assertEq(fraxStaker.proposedSlashingRecipientTimestamp(), 0);

        fraxStaker.proposeSlashingRecipientUpdate(bob);

        assertEq(fraxStaker.SLASHING_RECIPIENT(), address(0xdead));
        assertEq(fraxStaker.slashingRecipientUpdateDelay(), 7 days);
        assertEq(fraxStaker.proposedSlashingRecipient(), bob);
        assertEq(fraxStaker.proposedSlashingRecipientTimestamp(), block.timestamp + 7 days);

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(frank);
        fraxStaker.acceptSlashingRecipientUpdate();

        vm.expectRevert(SlashingRecipientUpdateNotAvailableYet.selector);
        fraxStaker.acceptSlashingRecipientUpdate();

        skip(7 days);

        vm.expectEmit(true, true, false, true);
        emit SlashingRecipientUpdated(address(0xdead), bob);
        fraxStaker.acceptSlashingRecipientUpdate();

        assertEq(fraxStaker.SLASHING_RECIPIENT(), bob);
        assertEq(fraxStaker.slashingRecipientUpdateDelay(), 7 days);
        assertEq(fraxStaker.proposedSlashingRecipient(), address(0));
        assertEq(fraxStaker.proposedSlashingRecipientTimestamp(), 0);

        vm.expectRevert(NoProposedSlashingRecipient.selector);
        fraxStaker.acceptSlashingRecipientUpdate();
    }

    function test_slashStaker() public {
        fraxStakerSetup();

        vm.expectRevert(NotFraxSentinel.selector);
        vm.prank(frank);
        fraxStaker.slashStaker(bob, 100e18);

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        vm.prank(alice);
        fraxStaker.stakeFrax{ value: 70e18 }();

        assertEq(fraxStaker.totalSupply(), 120e18);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertEq(fraxStaker.balanceOf(alice), 70e18);
        assertEq(address(fraxStaker).balance, 120e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);
        assertApproxEqAbs(alice.balance, aliceBalance - 70e18, 1e15);
        assertEq(fraxStaker.SLASHING_RECIPIENT().balance, 0);

        fraxStaker.addFraxSentinel(claire);

        vm.expectEmit(true, false, false, true);
        emit Slashed(bob, 30e18);
        vm.prank(claire);
        fraxStaker.slashStaker(bob, 30e18);

        assertEq(fraxStaker.totalSupply(), 90e18);
        assertEq(fraxStaker.balanceOf(bob), 20e18);
        assertEq(fraxStaker.balanceOf(alice), 70e18);
        assertEq(address(fraxStaker).balance, 90e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);
        assertApproxEqAbs(alice.balance, aliceBalance - 70e18, 1e15);
        assertEq(fraxStaker.SLASHING_RECIPIENT().balance, 30e18);

        vm.expectEmit(true, false, false, true);
        emit Slashed(alice, 70e18);
        vm.prank(claire);
        fraxStaker.slashStaker(alice, 90e18);

        assertEq(fraxStaker.totalSupply(), 20e18);
        assertEq(fraxStaker.balanceOf(bob), 20e18);
        assertEq(fraxStaker.balanceOf(alice), 0);
        assertEq(address(fraxStaker).balance, 20e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);
        assertApproxEqAbs(alice.balance, aliceBalance - 70e18, 1e15);
        assertEq(fraxStaker.SLASHING_RECIPIENT().balance, 100e18);
    }

    function test_freezeStaker() public {
        fraxStakerSetup();

        vm.expectRevert(NotFraxSentinel.selector);
        vm.prank(frank);
        fraxStaker.freezeStaker(bob);

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);

        fraxStaker.addFraxSentinel(claire);

        vm.expectEmit(true, false, false, true);
        emit StakerFrozen(bob, 50e18);
        vm.prank(claire);
        fraxStaker.freezeStaker(bob);

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(bob), 0);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);

        vm.expectRevert(AlreadyFrozenStaker.selector);
        vm.prank(claire);
        fraxStaker.freezeStaker(bob);

        vm.expectRevert(InvalidStakeAmount.selector);
        vm.prank(claire);
        fraxStaker.freezeStaker(alice);

        vm.expectRevert(FrozenStaker.selector);
        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 10e18 }();

        vm.expectRevert(FrozenStaker.selector);
        vm.prank(bob);
        fraxStaker.initiateWithdrawal();

        vm.expectRevert(FrozenStaker.selector);
        vm.prank(bob);
        fraxStaker.withdrawStake();
    }

    function test_unfreezeStaker() public {
        fraxStakerSetup();

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);

        fraxStaker.addFraxSentinel(claire);

        vm.expectEmit(true, false, false, true);
        emit StakerFrozen(bob, 50e18);
        vm.prank(claire);
        fraxStaker.freezeStaker(bob);

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(bob), 0);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);

        vm.expectRevert(NotFraxSentinel.selector);
        vm.prank(frank);
        fraxStaker.unfreezeStaker(bob);

        vm.expectEmit(true, false, false, true);
        emit StakerUnfrozen(bob, 50e18);
        vm.prank(claire);
        fraxStaker.unfreezeStaker(bob);

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);

        vm.expectRevert(NotFrozenStaker.selector);
        vm.prank(claire);
        fraxStaker.unfreezeStaker(bob);
    }

    function test_blacklistStaker() public {
        fraxStakerSetup();

        vm.expectRevert(NotFraxSentinel.selector);
        vm.prank(frank);
        fraxStaker.blacklistStaker(bob);

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);

        fraxStaker.addFraxSentinel(claire);

        vm.expectEmit(true, false, false, true);
        emit StakerBlacklisted(bob, 50e18);
        vm.prank(claire);
        fraxStaker.blacklistStaker(bob);

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(bob), 0);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(bob.balance, bobBalance - 50e18, 1e15);

        vm.expectRevert(AlreadyBlacklistedStaker.selector);
        vm.prank(claire);
        fraxStaker.blacklistStaker(bob);

        vm.prank(alice);
        fraxStaker.stakeFrax{ value: 70e18 }();

        assertEq(fraxStaker.totalSupply(), 120e18);
        assertEq(fraxStaker.balanceOf(alice), 70e18);
        assertEq(address(fraxStaker).balance, 120e18);
        assertApproxEqAbs(alice.balance, aliceBalance - 70e18, 1e15);

        vm.prank(claire);
        fraxStaker.freezeStaker(alice);

        assertEq(fraxStaker.totalSupply(), 120e18);
        assertEq(fraxStaker.balanceOf(alice), 0);
        assertEq(address(fraxStaker).balance, 120e18);
        assertApproxEqAbs(alice.balance, aliceBalance - 70e18, 1e15);
        assertTrue(fraxStaker.isFrozenStaker(alice));
        assertFalse(fraxStaker.blacklist(alice));

        vm.expectEmit(true, false, false, true);
        emit StakerUnfrozen(alice, 70e18);
        vm.expectEmit(true, false, false, true);
        emit StakeWithdrawalInitiated(alice, 70e18, block.timestamp + 90 days);
        vm.expectEmit(true, false, false, true);
        emit StakerBlacklisted(alice, 70e18);
        vm.prank(claire);
        fraxStaker.blacklistStaker(alice);

        assertEq(fraxStaker.totalSupply(), 120e18);
        assertEq(fraxStaker.balanceOf(alice), 0);
        assertEq(address(fraxStaker).balance, 120e18);
        assertApproxEqAbs(alice.balance, aliceBalance - 70e18, 1e15);
        assertFalse(fraxStaker.isFrozenStaker(alice));
        assertTrue(fraxStaker.blacklist(alice));

        vm.expectRevert(BlacklistedStaker.selector);
        vm.prank(alice);
        fraxStaker.stakeFrax{ value: 10e18 }();

        vm.expectRevert(BlacklistedStaker.selector);
        vm.prank(alice);
        fraxStaker.initiateWithdrawal();

        skip(90 days);

        vm.expectEmit(true, false, false, true);
        emit StakeUpdated(alice, 70e18, 0);
        vm.prank(alice);
        fraxStaker.withdrawStake();

        assertEq(fraxStaker.totalSupply(), 50e18);
        assertEq(fraxStaker.balanceOf(alice), 0);
        assertEq(address(fraxStaker).balance, 50e18);
        assertApproxEqAbs(alice.balance, aliceBalance, 1e15);
        assertFalse(fraxStaker.isFrozenStaker(alice));
        assertTrue(fraxStaker.blacklist(alice));

        vm.prank(frank);
        fraxStaker.stakeFrax{ value: 100e18 }();
        address mockAddress = address(uint160(257));

        vm.startPrank(frank);
        for (uint8 i; i < 255;) {
            fraxStaker.delegateStake(mockAddress, 1e15);

            mockAddress = address(uint160(i + 1));

            unchecked {
                ++i;
            }
        }
        vm.stopPrank();

        uint8 delegationsNumber;
        (,,,, delegationsNumber,) = fraxStaker.stakes(frank);
        assertEq(delegationsNumber, 255);

        vm.prank(claire);
        fraxStaker.blacklistStaker(frank);

        (,,,, delegationsNumber,) = fraxStaker.stakes(frank);
        assertEq(delegationsNumber, 0);
    }

    function test_delegateStake() public {
        fraxStakerSetup();

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();
        vm.prank(alice);
        fraxStaker.stakeFrax{ value: 30e18 }();

        vm.expectRevert(InvalidStakeAmount.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 60e18);

        Stake memory stakeEntry;
        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.amountDelegated, 0);
        assertEq(stakeEntry.amountDelegatedToStaker, 0);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 0);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), address(0));
        assertEq(fraxStaker.stakerDelegatees(bob, 1), address(0));

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(alice);

        assertEq(stakeEntry.amountStaked, 30e18);
        assertEq(stakeEntry.amountDelegated, 0);
        assertEq(stakeEntry.amountDelegatedToStaker, 0);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 0);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(alice), 30e18);
        assertEq(fraxStaker.stakerDelegatees(alice, 0), address(0));
        assertEq(fraxStaker.stakerDelegatees(alice, 1), address(0));

        vm.expectEmit(true, true, false, true);
        emit StakeDelegated(bob, alice, 20e18);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 20e18);

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.amountDelegated, 20e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 0);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 1);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 30e18);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), alice);
        assertEq(fraxStaker.stakerDelegatees(bob, 1), address(0));

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(alice);

        assertEq(stakeEntry.amountStaked, 30e18);
        assertEq(stakeEntry.amountDelegated, 0);
        assertEq(stakeEntry.amountDelegatedToStaker, 20e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 0);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(alice), 50e18);
        assertEq(fraxStaker.stakerDelegatees(alice, 0), address(0));
        assertEq(fraxStaker.stakerDelegatees(alice, 1), address(0));

        vm.expectEmit(true, true, false, true);
        emit StakeDelegated(alice, bob, 10e18);
        vm.prank(alice);
        fraxStaker.delegateStake(bob, 10e18);

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.amountDelegated, 20e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 10e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 1);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 40e18);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), alice);
        assertEq(fraxStaker.stakerDelegatees(bob, 1), address(0));

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(alice);

        assertEq(stakeEntry.amountStaked, 30e18);
        assertEq(stakeEntry.amountDelegated, 10e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 20e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 1);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(alice), 40e18);
        assertEq(fraxStaker.stakerDelegatees(alice, 0), bob);
        assertEq(fraxStaker.stakerDelegatees(alice, 1), address(0));

        vm.expectRevert(CannotDelegateToSelf.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(bob, 10e18);

        vm.expectRevert(InvalidStakeAmount.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 50e18);

        uint8 currentDelegationCount = stakeEntry.numberOfDelegations;
        address mockDelegatee = address(uint160(currentDelegationCount));
        while (currentDelegationCount < 255) {
            vm.prank(alice);
            fraxStaker.delegateStake(mockDelegatee, 1);

            currentDelegationCount++;
            mockDelegatee = address(uint160(currentDelegationCount));
        }

        vm.expectRevert(TooManyDelegations.selector);
        vm.prank(alice);
        fraxStaker.delegateStake(mockDelegatee, 1);

        fraxStaker.addFraxSentinel(frank);

        vm.prank(frank);
        fraxStaker.freezeStaker(alice);

        vm.expectRevert(FrozenStaker.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 10e18);

        vm.prank(frank);
        fraxStaker.blacklistStaker(alice);

        vm.expectRevert(BlacklistedStaker.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 10e18);

        vm.prank(frank);
        fraxStaker.freezeStaker(bob);

        vm.expectRevert(FrozenStaker.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 10e18);

        vm.prank(frank);
        fraxStaker.blacklistStaker(bob);

        vm.expectRevert(BlacklistedStaker.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 10e18);

        vm.prank(frank);
        fraxStaker.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        vm.prank(bob);
        fraxStaker.delegateStake(alice, 10e18);
    }

    function test_revokeDelegation() public {
        fraxStakerSetup();

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();
        vm.prank(alice);
        fraxStaker.stakeFrax{ value: 30e18 }();

        vm.prank(bob);
        fraxStaker.delegateStake(alice, 20e18);
        vm.prank(alice);
        fraxStaker.delegateStake(bob, 10e18);

        Stake memory stakeEntry;
        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.amountDelegated, 20e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 10e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 1);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 40e18);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), alice);
        assertEq(fraxStaker.stakerDelegatees(bob, 1), address(0));

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(alice);

        assertEq(stakeEntry.amountStaked, 30e18);
        assertEq(stakeEntry.amountDelegated, 10e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 20e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 1);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(alice), 40e18);
        assertEq(fraxStaker.stakerDelegatees(alice, 0), bob);
        assertEq(fraxStaker.stakerDelegatees(alice, 1), address(0));

        vm.expectRevert(InvalidStakeAmount.selector);
        vm.prank(bob);
        fraxStaker.revokeDelegation(frank);

        vm.prank(bob);
        fraxStaker.delegateStake(frank, 10e18);
        vm.prank(bob);
        fraxStaker.delegateStake(address(uint160(42)), 5e18);

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.amountDelegated, 35e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 10e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 3);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 25e18);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), alice);
        assertEq(fraxStaker.stakerDelegatees(bob, 1), frank);
        assertEq(fraxStaker.stakerDelegatees(bob, 2), address(uint160(42)));
        assertEq(fraxStaker.stakerDelegatees(bob, 3), address(0));

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(alice);

        assertEq(stakeEntry.amountStaked, 30e18);
        assertEq(stakeEntry.amountDelegated, 10e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 20e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 1);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(alice), 40e18);
        assertEq(fraxStaker.stakerDelegatees(alice, 0), bob);
        assertEq(fraxStaker.stakerDelegatees(alice, 1), address(0));

        vm.expectEmit(true, true, false, true);
        emit StakeDelegationRevoked(bob, alice, 20e18);
        vm.prank(bob);
        fraxStaker.revokeDelegation(alice);

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(bob);

        assertEq(stakeEntry.amountStaked, 50e18);
        assertEq(stakeEntry.amountDelegated, 15e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 10e18);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 2);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(bob), 45e18);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), address(uint160(42)));
        assertEq(fraxStaker.stakerDelegatees(bob, 1), frank);
        assertEq(fraxStaker.stakerDelegatees(bob, 2), address(0));
        assertEq(fraxStaker.stakerDelegatees(bob, 3), address(0));

        (stakeEntry.amountStaked, stakeEntry.amountDelegated, stakeEntry.amountDelegatedToStaker, stakeEntry.unlockTime, stakeEntry.numberOfDelegations, stakeEntry.initiatedWithdrawal) = fraxStaker.stakes(alice);

        assertEq(stakeEntry.amountStaked, 30e18);
        assertEq(stakeEntry.amountDelegated, 10e18);
        assertEq(stakeEntry.amountDelegatedToStaker, 0);
        assertEq(stakeEntry.unlockTime, 0);
        assertEq(stakeEntry.numberOfDelegations, 1);
        assertFalse(stakeEntry.initiatedWithdrawal);
        assertEq(fraxStaker.balanceOf(alice), 20e18);
        assertEq(fraxStaker.stakerDelegatees(alice, 0), bob);
        assertEq(fraxStaker.stakerDelegatees(alice, 1), address(0));

        fraxStaker.addFraxSentinel(frank);
        vm.prank(frank);
        fraxStaker.freezeStaker(bob);

        vm.expectRevert(FrozenStaker.selector);
        vm.prank(bob);
        fraxStaker.revokeDelegation(frank);

        vm.prank(frank);
        fraxStaker.blacklistStaker(bob);

        vm.expectRevert(BlacklistedStaker.selector);
        vm.prank(bob);
        fraxStaker.revokeDelegation(frank);

        vm.prank(frank);
        fraxStaker.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        vm.prank(bob);
        fraxStaker.revokeDelegation(frank);
    }

    function test_revokeAllDelegations() public {
        fraxStakerSetup();

        vm.prank(bob);
        fraxStaker.stakeFrax{ value: 50e18 }();

        uint8 delegationsNumber;
        (,,,, delegationsNumber,) = fraxStaker.stakes(bob);
        assertEq(delegationsNumber, 0);

        address mockAddress;

        vm.startPrank(bob);
        for (uint8 i; i < 255;) {
            mockAddress = address(uint160(i + 1));

            fraxStaker.delegateStake(mockAddress, 1e15);

            unchecked {
                ++i;
            }
        }
        vm.stopPrank();

        (,,,, delegationsNumber,) = fraxStaker.stakes(bob);
        assertEq(delegationsNumber, 255);

        uint256 amountDelegated;
        (,, amountDelegated,,,) = fraxStaker.stakes(mockAddress);
        assertEq(amountDelegated, 1e15);
        assertEq(fraxStaker.balanceOf(bob), 50e18 - 255 * 1e15);
        assertEq(fraxStaker.balanceOf(mockAddress), 1e15);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), address(1));
        assertEq(fraxStaker.stakerDelegatees(bob, 254), mockAddress);

        vm.prank(bob);
        fraxStaker.revokeAllDelegations();

        (,,,, delegationsNumber,) = fraxStaker.stakes(bob);
        assertEq(delegationsNumber, 0);

        (,, amountDelegated,,,) = fraxStaker.stakes(mockAddress);
        assertEq(amountDelegated, 0);
        assertEq(fraxStaker.balanceOf(bob), 50e18);
        assertEq(fraxStaker.balanceOf(mockAddress), 0);
        assertEq(fraxStaker.stakerDelegatees(bob, 0), address(0));
        assertEq(fraxStaker.stakerDelegatees(bob, 1), address(0));
        assertEq(fraxStaker.stakerDelegatees(bob, 254), address(0));

        fraxStaker.addFraxSentinel(frank);
        vm.prank(frank);
        fraxStaker.freezeStaker(bob);

        vm.expectRevert(FrozenStaker.selector);
        vm.prank(bob);
        fraxStaker.revokeAllDelegations();

        vm.prank(frank);
        fraxStaker.blacklistStaker(bob);

        vm.expectRevert(BlacklistedStaker.selector);
        vm.prank(bob);
        fraxStaker.revokeAllDelegations();

        vm.prank(frank);
        fraxStaker.stopOperation();

        vm.expectRevert(ContractPaused.selector);
        vm.prank(bob);
        fraxStaker.revokeAllDelegations();
    }
}
