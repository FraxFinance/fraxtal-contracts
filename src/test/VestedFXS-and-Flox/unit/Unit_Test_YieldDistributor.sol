// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import "../BaseTestVeFXS.t.sol";
import "../helpers/MintableERC20.sol";
import "../../../contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXS.sol";
import "../../../contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import "../../../contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import "../../../contracts/VestedFXS-and-Flox/VestedFXS/YieldDistributor.sol";

contract Unit_Test_YieldDistributor is BaseTestVeFXS {
    using stdStorage for StdStorage;

    uint128 endTimestamp;

    function setUp() public {
        defaultSetup();

        // Set up the test
        token.mint(alice, 1000e18);
        token.mint(bob, 1000e18);
        token.mint(address(this), 1000e18);
        token.approve(address(yieldDistributor), 1000e18);
        hoax(bob);
        token.approve(address(vestedFXS), 1000e18);

        // Set the YieldDistributor owner to Alice for these tests
        yieldDistributor.nominateNewOwner(alice);
        hoax(alice);
        yieldDistributor.acceptOwnership();
    }

    function _doInitialBobLock() public {
        hoax(bob);
        token.approve(address(yieldDistributor), 1000e18);
        endTimestamp = (uint128(block.timestamp) + MAXTIME_UINT128) / WEEK_UINT128 * WEEK_UINT128;
        hoax(bob);
        console.log("<<<Setup Bob's initial createLock>>>");
        vestedFXS.createLock(bob, 5e18, endTimestamp);
    }

    function _setAliceAsTimelock() public {
        // Set the YieldDistributor timelock to Alice for these tests
        yieldDistributor.setTimelock(alice);
    }

    function test_CheckpointNormal() public {
        _doInitialBobLock();

        uint256 startTimestamp = block.timestamp;

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0, "yieldPerVeFXSStored [A]");
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), 0, "totalComboVeFXSSupplyStored [A]");
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp, "lastUpdateTime [A]");

        skip(604_800);

        hoax(bob);
        console.log("<<<Before checkpoint 1>>>");
        yieldDistributor.checkpoint();
        console.log("<<<After checkpoint 1>>>");

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0, "yieldPerVeFXSStored [B]");
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.totalSupply(0), "totalComboVeFXSSupplyStored [B]");
        assertEq(yieldDistributor.lastUpdateTime(), 0, "lastUpdateTime [B]");
        assertEq(yieldDistributor.yields(bob), 0, "yields [B]");
        assertEq(yieldDistributor.userYieldPerTokenPaid(bob), 0, "userYieldPerTokenPaid [B]");
        assertEq(yieldDistributor.userVeFXSCheckpointed(bob), vestedFXS.balanceOf(bob), "userVeFXSCheckpointed [B]");
        assertEq(yieldDistributor.userVeFXSEndpointCheckpointed(bob), endTimestamp, "userVeFXSEndpointCheckpointed [B]");
        assertEq(yieldDistributor.totalVeFXSParticipating(), vestedFXS.balanceOf(bob), "totalVeFXSParticipating [B]");

        uint256 balanceBob = vestedFXS.balanceOf(bob);
        uint256 expectedFraction = (balanceBob * 1e6) / vestedFXS.totalSupply(0);
        assertEq(yieldDistributor.fractionParticipating(), expectedFraction, "fractionParticipating [B]");

        console.log("<<<Before reward-notification 1>>>");
        yieldDistributor.toggleRewardNotifier(bob);
        yieldDistributor.notifyRewardAmount(1e15);
        yieldDistributor.setYieldRate(1e5, true);
        console.log("<<<After reward-notification 1>>>");

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0, "yieldPerVeFXSStored [C]");
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.totalSupply(0), "totalComboVeFXSSupplyStored [C]");
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp + 604_800, "lastUpdateTime [C]");
        assertEq(yieldDistributor.yields(bob), 0, "yields [C]");
        assertEq(yieldDistributor.userYieldPerTokenPaid(bob), 0, "userYieldPerTokenPaid [C]");
        assertEq(yieldDistributor.userVeFXSCheckpointed(bob), balanceBob, "userVeFXSCheckpointed [C]");
        assertEq(yieldDistributor.userVeFXSEndpointCheckpointed(bob), endTimestamp, "userVeFXSEndpointCheckpointed [C]");
        assertEq(yieldDistributor.totalVeFXSParticipating(), balanceBob, "totalVeFXSParticipating [C]");
        expectedFraction = (balanceBob * 1e6) / vestedFXS.totalSupply(0);
        assertEq(yieldDistributor.fractionParticipating(), expectedFraction, "fractionParticipating [C]");

        uint256 totalSupplyBeforeLockCreation = vestedFXS.totalSupply();

        skip(302_400);

        uint128 newEndTimestamp = (endTimestamp - (MAXTIME_UINT128 / 2)) / WEEK_UINT128 * WEEK_UINT128;

        hoax(bob);
        console.log("<<<Before createLock and checkpoint 2>>>");
        vestedFXS.createLock(bob, 5e18, newEndTimestamp);
        hoax(bob);
        yieldDistributor.checkpoint();
        console.log("<<<After createLock and checkpoint 2>>>");

        uint256 yieldPerVefxs = yieldDistributor.yieldPerVeFXSStored();
        uint256 expectedYieldPerVefxs = (302_400 * 1e5 * 1e18) / totalSupplyBeforeLockCreation;
        uint256 yield = yieldDistributor.yields(bob);
        uint256 expectedYield = balanceBob * yieldPerVefxs * 1e6 / (1e18 * 1e6) + 0;

        assertEq(yieldDistributor.yieldPerVeFXSStored(), expectedYieldPerVefxs, "yieldPerVeFXSStored [D]");
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.totalSupply(), "totalComboVeFXSSupplyStored [D]");
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp + (302_400 * 3), "lastUpdateTime [D]");
        assertEq(yieldDistributor.yields(bob), expectedYield, "yields [D]");
        assertEq(yieldDistributor.userYieldPerTokenPaid(bob), expectedYieldPerVefxs, "userYieldPerTokenPaid [D]");
        assertEq(yieldDistributor.userVeFXSCheckpointed(bob), vestedFXS.balanceOf(bob), "userVeFXSCheckpointed [D]");
        assertEq(yieldDistributor.userVeFXSEndpointCheckpointed(bob), newEndTimestamp, "userVeFXSEndpointCheckpointed [D]");
        assertEq(yieldDistributor.totalVeFXSParticipating(), vestedFXS.balanceOf(bob), "totalVeFXSParticipating [D]");
        expectedFraction = (vestedFXS.balanceOf(bob) * 1e6) / vestedFXS.totalSupply(0);
        assertEq(yieldDistributor.fractionParticipating(), expectedFraction, "fractionParticipating [D]");

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);

        // // Sync
        // console.log("<<<Before checkpoint 3>>>");
        // yieldDistributor.checkpoint();
        // console.log("<<<After checkpoint 3>>>");

        // // Check everything again. Should be mostly the same as the period hasn't elapsed yet.
        // assertEq(yieldDistributor.yieldPerVeFXSStored(), expectedYieldPerVefxs, "yieldPerVeFXSStored [E]");
        // assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.totalSupply() + l1VeFXSTotalSupplyOracle.totalSupply(), "totalComboVeFXSSupplyStored [E]");
        // assertEq(yieldDistributor.lastUpdateTime(), startTimestamp + (302_400 * 3), "lastUpdateTime [E]");
        // assertEq(yieldDistributor.yields(bob), expectedYield, "yields [E]");
        // assertEq(yieldDistributor.userYieldPerTokenPaid(bob), expectedYieldPerVefxs, "userYieldPerTokenPaid [E]");
        // assertEq(yieldDistributor.userVeFXSCheckpointed(bob), vestedFXS.balanceOf(bob), "userVeFXSCheckpointed [E]");
        // assertEq(yieldDistributor.userVeFXSEndpointCheckpointed(bob), newEndTimestamp, "userVeFXSEndpointCheckpointed [E]");
        // assertEq(yieldDistributor.totalVeFXSParticipating(), vestedFXS.balanceOf(bob), "totalVeFXSParticipating [E]");
        // expectedFraction = (vestedFXS.balanceOf(bob) * 1e6) / yieldDistributor.ttlCombinedVeFXSTotalSupply();
        // assertEq(yieldDistributor.fractionParticipating(), expectedFraction, "fractionParticipating [E]");

        // // Bob collects rewards
        // hoax(bob);
        // yieldDistributor.getYield();

        // // Advance into the next period
        // skip(302_400);

        // // Notify the new reward
        // console.log("<<<Before reward-notification 2>>>");
        // yieldDistributor.notifyRewardAmount(1e15);
        // console.log("<<<After reward-notification 2>>>");

        // // Note bob's veFXS valance
        // balanceBob = yieldDistributor.ttlCombinedVeFXS(bob);
        // expectedFraction = (balanceBob * 1e6) / yieldDistributor.ttlCombinedVeFXSTotalSupply();

        // // Advance half a week
        // skip(302_400);

        // // Sync
        // console.log("<<<Before checkpoint 4>>>");
        // yieldDistributor.checkpoint();
        // console.log("<<<After checkpoint 4>>>");

        // // Check everything again. Should be different now because the total veFXS seen has dramatically increased
        // yieldPerVefxs = yieldDistributor.yieldPerVeFXSStored();
        // expectedYieldPerVefxs = (604_800 * 1e5 * 1e18) / yieldDistributor.ttlCombinedVeFXSTotalSupply();
        // yield = yieldDistributor.yields(bob);
        // expectedYield = balanceBob * yieldPerVefxs * 1e6 / (1e18 * 1e6) + 0;

        // assertEq(yieldDistributor.yieldPerVeFXSStored(), expectedYieldPerVefxs, "yieldPerVeFXSStored [F]");
        // assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.totalSupply() + l1VeFXSTotalSupplyOracle.totalSupply(), "totalComboVeFXSSupplyStored [F]");
        // assertEq(yieldDistributor.lastUpdateTime(), startTimestamp + (302_400 * 5), "lastUpdateTime [F]");
        // assertEq(yieldDistributor.yields(bob), expectedYield, "yields [F]");
        // assertEq(yieldDistributor.userYieldPerTokenPaid(bob), expectedYieldPerVefxs, "userYieldPerTokenPaid [F]");
        // assertEq(yieldDistributor.userVeFXSCheckpointed(bob), vestedFXS.balanceOf(bob), "userVeFXSCheckpointed [F]");
        // assertEq(yieldDistributor.userVeFXSEndpointCheckpointed(bob), newEndTimestamp, "userVeFXSEndpointCheckpointed [F]");
        // assertEq(yieldDistributor.totalVeFXSParticipating(), vestedFXS.balanceOf(bob), "totalVeFXSParticipating [F]");
        // expectedFraction = (vestedFXS.balanceOf(bob) * 1e6) / yieldDistributor.ttlCombinedVeFXSTotalSupply();
        // assertEq(yieldDistributor.fractionParticipating(), expectedFraction, "fractionParticipating [F]");
    }

    function test_CheckpointOtherUser() public {
        _doInitialBobLock();

        uint256 startTimestamp = block.timestamp;

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0);
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), 0);
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp);

        skip(604_800);
        console.log("<<<Before checkpointOtherUser>>>");
        yieldDistributor.checkpointOtherUser(bob);

        veFXSAggregator.getAllCurrActiveLocks(bob, true);

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0, "yieldPerVeFXSStored");
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.totalSupply(0), "totalComboVeFXSSupplyStored");
        assertEq(yieldDistributor.lastUpdateTime(), 0, "lastUpdateTime");
        assertEq(yieldDistributor.yields(bob), 0, "yields");
        assertEq(yieldDistributor.userYieldPerTokenPaid(bob), 0, "userYieldPerTokenPaid");
        assertEq(yieldDistributor.userVeFXSCheckpointed(bob), vestedFXS.balanceOf(bob), "userVeFXSCheckpointed");
        assertEq(yieldDistributor.userVeFXSEndpointCheckpointed(bob), endTimestamp, "userVeFXSEndpointCheckpointed");
        assertEq(yieldDistributor.totalVeFXSParticipating(), vestedFXS.balanceOf(bob), "totalVeFXSParticipating");

        console.log("<<<Before reward notification>>>");
        yieldDistributor.toggleRewardNotifier(bob);
        yieldDistributor.notifyRewardAmount(1e15);
        yieldDistributor.setYieldRate(1e5, true);

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0, "yieldPerVeFXSStored");
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.totalSupply(0), "totalComboVeFXSSupplyStored");
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp + 604_800, "lastUpdateTime");
        assertEq(yieldDistributor.yields(bob), 0, "yields");
        assertEq(yieldDistributor.userYieldPerTokenPaid(bob), 0, "userYieldPerTokenPaid");
        assertEq(yieldDistributor.userVeFXSCheckpointed(bob), vestedFXS.balanceOf(bob), "userVeFXSCheckpointed");
        assertEq(yieldDistributor.userVeFXSEndpointCheckpointed(bob), endTimestamp, "userVeFXSEndpointCheckpointed");
        assertEq(yieldDistributor.totalVeFXSParticipating(), vestedFXS.balanceOf(bob), "totalVeFXSParticipating");

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_GetYield() public {
        _doInitialBobLock();

        uint256 startTimestamp = block.timestamp;

        skip(604_800);
        console.log("<<<Before reward notification>>>");
        yieldDistributor.toggleRewardNotifier(bob);
        yieldDistributor.notifyRewardAmount(1e15);
        yieldDistributor.setYieldRate(1e5, true);

        hoax(bob);
        console.log("<<<Before checkpoint>>>");
        yieldDistributor.checkpoint();

        skip(604_800);

        uint256 expectedYield = yieldDistributor.earned(bob);

        vm.expectEmit(true, false, false, true, address(yieldDistributor));
        emit YieldDistributor.YieldCollected(bob, bob, expectedYield, address(token));
        hoax(bob);
        console.log("<<<Before getYield #1>>>");
        uint256 yieldAwarded = yieldDistributor.getYield();
        assertEq(yieldAwarded, expectedYield);

        yieldDistributor.greylistAddress(bob);
        vm.expectRevert(YieldDistributor.AddressGreylisted.selector);
        hoax(bob);
        console.log("<<<Before getYield #2 (will fail)>>>");
        yieldDistributor.getYield();

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_GetYieldThirdParty() public {
        _doInitialBobLock();

        uint256 startTimestamp = block.timestamp;

        skip(604_800);
        console.log("<<<Before reward notification>>>");
        yieldDistributor.toggleRewardNotifier(bob);
        yieldDistributor.notifyRewardAmount(1e15);
        yieldDistributor.setYieldRate(1e5, true);

        hoax(bob);
        console.log("<<<Before checkpoint>>>");
        yieldDistributor.checkpoint();

        skip(604_800);

        uint256 expectedYield = yieldDistributor.earned(bob);

        // Random person (Claire) tries (and fails) to claim Bob's yield
        hoax(claire);
        vm.expectRevert(YieldDistributor.SenderNotAuthorizedClaimer.selector);
        yieldDistributor.getYieldThirdParty(bob);

        // Admin lets Claire be a claimer for Bob
        yieldDistributor.setThirdPartyClaimer(bob, claire);

        // Claire can now claim Bob's rewards
        vm.expectEmit(true, true, true, true, address(yieldDistributor));
        emit YieldDistributor.YieldCollected(bob, claire, expectedYield, address(token));
        hoax(claire);
        console.log("<<<Before getYield #1>>>");
        uint256 yieldAwarded = yieldDistributor.getYieldThirdParty(bob);
        assertEq(yieldAwarded, expectedYield);

        // Claire cannot claim Bob's rewards if Bob is greylisted
        yieldDistributor.greylistAddress(bob);
        vm.expectRevert(YieldDistributor.AddressGreylisted.selector);
        hoax(claire);
        console.log("<<<Before getYield #2 (will fail)>>>");
        yieldDistributor.getYieldThirdParty(bob);

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_Sync() public {
        _doInitialBobLock();

        uint256 startTimestamp = block.timestamp;

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0);
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), 0);
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp);

        console.log("<<<Before sync #1>>>");
        yieldDistributor.sync();

        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0);
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.balanceOf(bob));
        assertEq(yieldDistributor.lastUpdateTime(), 0);

        skip(604_800);

        console.log("<<<Before reward toggling>>>");
        yieldDistributor.toggleRewardNotifier(bob);
        yieldDistributor.notifyRewardAmount(1e15);
        yieldDistributor.setYieldRate(1e5, true);

        console.log("<<<Before sync #2>>>");
        yieldDistributor.sync();

        assertEq(yieldDistributor.yieldPerVeFXSStored(), yieldDistributor.yieldPerVeFXS());
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.balanceOf(bob));
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp + 604_800);

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_NotifyRewardAmount() public {
        _doInitialBobLock();

        uint256 startTimestamp = block.timestamp;

        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp);
        assertEq(yieldDistributor.periodFinish(), 0);
        assertEq(yieldDistributor.yieldRate(), 0);

        console.log("<<<Before toggling reward notifier>>>");
        yieldDistributor.toggleRewardNotifier(bob);
        hoax(bob);
        token.approve(address(yieldDistributor), 1e15);
        uint256 amount = 1e15;
        uint256 yieldRate = amount / 604_800;
        vm.expectEmit(false, false, false, true, address(yieldDistributor));
        emit YieldDistributor.RewardAdded(amount, yieldRate);
        hoax(bob);
        console.log("<<<Before reward notification>>>");
        yieldDistributor.notifyRewardAmount(amount);

        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp);
        assertEq(yieldDistributor.periodFinish(), startTimestamp + 604_800);
        assertEq(yieldDistributor.yieldRate(), yieldRate);

        console.log("<<<Before toggling reward notifier again>>>");
        yieldDistributor.toggleRewardNotifier(bob);
        vm.expectRevert(YieldDistributor.SenderNotRewarder.selector);
        hoax(bob);
        console.log("<<<Before reward notification (will fail)>>>");
        yieldDistributor.notifyRewardAmount(amount);

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_RecoverERC20() public {
        MintableERC20 unrelatedToken = new MintableERC20("mock Unrelated Token", "mUT");
        unrelatedToken.mint(address(yieldDistributor), 1e18);

        vm.expectEmit(false, false, false, true, address(yieldDistributor));
        emit YieldDistributor.RecoveredERC20(address(unrelatedToken), 1e17);
        yieldDistributor.recoverERC20(address(unrelatedToken), 1e17);

        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        hoax(bob);
        yieldDistributor.recoverERC20(address(unrelatedToken), 1e18);
    }

    function test_SetYieldDuration() public {
        _doInitialBobLock();

        uint256 startTimestamp = block.timestamp;

        assertEq(yieldDistributor.yieldDuration(), 604_800);

        uint256 yieldDuration = 42_000;
        vm.expectEmit(false, false, false, true);
        emit YieldDistributor.YieldDurationUpdated(yieldDuration);
        yieldDistributor.setYieldDuration(yieldDuration);

        assertEq(yieldDistributor.yieldDuration(), yieldDuration);

        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        hoax(bob);
        yieldDistributor.setYieldDuration(yieldDuration);

        yieldDistributor.toggleRewardNotifier(bob);
        hoax(bob);
        yieldDistributor.notifyRewardAmount(1e15);

        vm.expectRevert(YieldDistributor.YieldPeriodMustCompleteBeforeChangingToNewPeriod.selector);
        yieldDistributor.setYieldDuration(yieldDuration);
    }

    function test_GreylistAddress() public {
        assertFalse(yieldDistributor.greylist(bob));

        yieldDistributor.greylistAddress(bob);

        assertTrue(yieldDistributor.greylist(bob));

        hoax(alice);
        yieldDistributor.greylistAddress(bob);

        assertFalse(yieldDistributor.greylist(bob));

        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        hoax(bob);
        yieldDistributor.greylistAddress(bob);
    }

    function test_ToggleRewardNotifier() public {
        assertFalse(yieldDistributor.rewardNotifiers(bob));

        yieldDistributor.toggleRewardNotifier(bob);

        assertTrue(yieldDistributor.rewardNotifiers(bob));

        hoax(alice);
        yieldDistributor.toggleRewardNotifier(bob);

        assertFalse(yieldDistributor.rewardNotifiers(bob));

        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        hoax(bob);
        yieldDistributor.toggleRewardNotifier(bob);
    }

    function test_SetPauses() public {
        assertFalse(yieldDistributor.yieldCollectionPaused());

        yieldDistributor.setPauses(true);

        assertTrue(yieldDistributor.yieldCollectionPaused());

        yieldDistributor.setPauses(true);

        assertTrue(yieldDistributor.yieldCollectionPaused());

        hoax(alice);
        yieldDistributor.setPauses(false);

        assertFalse(yieldDistributor.yieldCollectionPaused());

        yieldDistributor.setPauses(false);

        assertFalse(yieldDistributor.yieldCollectionPaused());

        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        hoax(bob);
        yieldDistributor.setPauses(true);
    }

    function test_SetYieldRate() public {
        uint256 startTimestamp = block.timestamp;

        assertEq(yieldDistributor.yieldRate(), 0);

        uint256 yieldRate = 1e5;

        yieldDistributor.setYieldRate(yieldRate, false);

        assertEq(yieldDistributor.yieldRate(), yieldRate);

        assertEq(yieldDistributor.yieldRate(), yieldRate);
        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0);
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), 0);
        assertEq(yieldDistributor.lastUpdateTime(), startTimestamp);

        hoax(alice);
        yieldDistributor.setYieldRate(yieldRate * 2, true);

        assertEq(yieldDistributor.yieldRate(), yieldRate * 2);
        assertEq(yieldDistributor.yieldPerVeFXSStored(), 0);
        assertEq(yieldDistributor.totalComboVeFXSSupplyStored(), vestedFXS.balanceOf(bob));
        assertEq(yieldDistributor.lastUpdateTime(), 0);

        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        hoax(bob);
        yieldDistributor.setYieldRate(yieldRate, false);

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_setVeFXSAggregator() public {
        setUp();

        // Random user Claire should not be able to set the aggregator
        hoax(claire);
        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        yieldDistributor.setVeFXSAggregator(address(veFXSAggregator));

        // Owner should be able to set the aggregator
        yieldDistributor.setVeFXSAggregator(address(veFXSAggregator));
    }

    function test_delayedSecondNotifyReward() public {
        setUp();

        // Bob does a lock
        hoax(bob);
        vestedFXS.createLock(bob, 10e18, uint128(block.timestamp + (60 * DAY)));

        // Notify a reward
        token.approve(address(yieldDistributor), 1000e18);
        yieldDistributor.notifyRewardAmount(7e18);

        // Bob checkpoints on the YD
        hoax(bob);
        yieldDistributor.checkpoint();

        // Wait a week
        _warpToAndRollOne(block.timestamp + (7 * DAY));

        // Bob should have earned all of the yield
        assertApproxEqRel(yieldDistributor.earned(bob), 7e18, 0.01e18, "Bob should have earned all of the yield");

        // Wait 3 days
        _warpToAndRollOne(block.timestamp + (3 * DAY));

        // Bob should have earned nothing extra
        assertApproxEqRel(yieldDistributor.earned(bob), 7e18, 0.01e18, "Bob should have earned nothing extra");

        // Notify another reward, this time at double the rate
        token.approve(address(yieldDistributor), 1000e18);
        yieldDistributor.notifyRewardAmount(14e18);

        // Wait 1 day
        _warpToAndRollOne(block.timestamp + (1 * DAY));

        // Bob should have earned 2 more FXS
        assertApproxEqRel(yieldDistributor.earned(bob), 9e18, 0.01e18, "Bob should have earned 2 more FXS");
    }

    function test_onlySporadicRewards() public {
        setUp();

        // Bob does a lock
        hoax(bob);
        vestedFXS.createLock(bob, 10e18, uint128(block.timestamp + (180 * DAY)));

        // Bob checkpoints on the YD
        hoax(bob);
        yieldDistributor.checkpoint();

        // Wait 10 days
        _warpToAndRollOne(block.timestamp + (10 * DAY));

        // Notify a reward
        token.approve(address(yieldDistributor), 1000e18);
        yieldDistributor.notifyRewardAmount(7e18);

        // Wait a week
        _warpToAndRollOne(block.timestamp + (7 * DAY));

        // Bob should have earned all of the yield
        assertApproxEqRel(yieldDistributor.earned(bob), 7e18, 0.01e18, "Bob should have earned all of the yield");

        // Wait 3 days
        _warpToAndRollOne(block.timestamp + (3 * DAY));

        // Bob should have earned nothing extra
        assertApproxEqRel(yieldDistributor.earned(bob), 7e18, 0.01e18, "Bob should have earned nothing extra");

        // Wait 18 days
        _warpToAndRollOne(block.timestamp + (18 * DAY));

        // Notify another reward, this time at double the rate
        yieldDistributor.notifyRewardAmount(14e18);

        // Wait 1 day
        _warpToAndRollOne(block.timestamp + (1 * DAY));

        // Bob should have earned only 2 more FXS
        assertApproxEqRel(yieldDistributor.earned(bob), 9e18, 0.01e18, "Bob should have earned 2 more FXS");

        // Wait 30 days
        _warpToAndRollOne(block.timestamp + (30 * DAY));

        // Bob should have earned 7 + 14 = 21
        assertApproxEqRel(yieldDistributor.earned(bob), 21e18, 0.01e18, "Bob should have earned 21 FXS");

        // Notify another reward, this time at half the original rate
        yieldDistributor.notifyRewardAmount(3.5e18);

        // Wait 2 days
        _warpToAndRollOne(block.timestamp + (2 * DAY));

        // Bob should have earned 21 + 1 = 22
        assertApproxEqRel(yieldDistributor.earned(bob), 22e18, 0.01e18, "Bob should have earned 22 FXS");

        // Wait 60 days
        _warpToAndRollOne(block.timestamp + (60 * DAY));

        // Bob should have earned 22 + 2.5 = 24.5
        assertApproxEqRel(yieldDistributor.earned(bob), 24.5e18, 0.01e18, "Bob should have earned 24.5 FXS");
    }

    function test_SetTimelock() public {
        // Set Alice as the timelock
        _setAliceAsTimelock();

        assertEq(yieldDistributor.timelockAddress(), alice);

        console.log("<<<Alice sets Bob as TL>>>");
        hoax(alice);
        yieldDistributor.setTimelock(bob);
        assertEq(yieldDistributor.timelockAddress(), bob);

        console.log("<<<Bob sets Alice as TL>>>");
        hoax(bob);
        yieldDistributor.setTimelock(alice);
        assertEq(yieldDistributor.timelockAddress(), alice);

        console.log("<<<Bob tries to set Alice as TL again but fails>>>");
        hoax(bob);
        vm.expectRevert(YieldDistributor.NotOwnerOrTimelock.selector);
        yieldDistributor.setTimelock(alice);
    }

    function test_GetYieldForDuration() public {
        uint256 yieldRate = 1e5;

        yieldDistributor.setYieldRate(yieldRate, false);

        assertEq(yieldDistributor.getYieldForDuration(), yieldRate * 604_800);
    }

    function test_Earned() public {
        _doInitialBobLock();

        assertEq(yieldDistributor.earned(bob), 0);

        yieldDistributor.notifyRewardAmount(1e15);
        yieldDistributor.setYieldRate(1e5, true);
        address[] memory _tmpAddrArr = new address[](1);
        _tmpAddrArr[0] = bob;
        yieldDistributor.bulkCheckpointOtherUsers(_tmpAddrArr);

        yieldDistributor.earned(bob);

        skip(MAXTIME_UINT128);
        yieldDistributor.earned(bob);
        uint256 fee = vestedFXS.balanceOf(bob);

        yieldDistributor.checkpointOtherUser(bob);
        assertEq(yieldDistributor.earned(bob), 0);
    }

    function test_FractionParticipating() public {
        _doInitialBobLock();

        yieldDistributor.sync();
        yieldDistributor.checkpointOtherUser(bob);

        uint256 initialBobBalance = vestedFXS.balanceOf(bob);
        uint256 initialTotalSupply = vestedFXS.totalSupply(0);
        uint256 expectedFraction = (initialBobBalance * 1e6) / initialTotalSupply;

        assertEq(yieldDistributor.fractionParticipating(), expectedFraction);

        token.mint(alice, 100e18);
        hoax(alice);
        token.approve(address(vestedFXS), 100e18);
        hoax(alice);
        vestedFXS.createLock(alice, 10e18, endTimestamp);

        assertEq(yieldDistributor.fractionParticipating(), expectedFraction);

        yieldDistributor.sync();

        uint256 updatedTotalSupply = vestedFXS.totalSupply(0);
        uint256 updatedExpectedFraction = (initialBobBalance * 1e6) / updatedTotalSupply;

        assertGt(expectedFraction, updatedExpectedFraction);
        assertEq(yieldDistributor.fractionParticipating(), updatedExpectedFraction);

        yieldDistributor.checkpointOtherUser(alice);

        uint256 initialAliceBalance = vestedFXS.balanceOf(alice);
        uint256 finalExpectedFraction = ((initialBobBalance + initialAliceBalance) * 1e6) / updatedTotalSupply;

        assertEq(yieldDistributor.fractionParticipating(), finalExpectedFraction);
        assertGt(finalExpectedFraction, updatedExpectedFraction);
        assertEq(expectedFraction, finalExpectedFraction);

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_EligibleCurrentVeFXS() public {
        _doInitialBobLock();

        uint256 expectedEligibleVefxsBal = 0;
        uint256 expectedEndingTimestamp = 0;
        uint256 retrievedEligibleVefxsBal;
        uint256 retrievedEndingTimestamp;

        (retrievedEligibleVefxsBal, retrievedEndingTimestamp) = yieldDistributor.eligibleCurrentVeFXS(bob);

        assertEq(retrievedEligibleVefxsBal, expectedEligibleVefxsBal);
        assertEq(retrievedEndingTimestamp, expectedEndingTimestamp);

        yieldDistributor.sync();
        yieldDistributor.checkpointOtherUser(bob);

        expectedEligibleVefxsBal = vestedFXS.balanceOf(bob);
        expectedEndingTimestamp = endTimestamp;
        (retrievedEligibleVefxsBal, retrievedEndingTimestamp) = yieldDistributor.eligibleCurrentVeFXS(bob);

        assertEq(retrievedEligibleVefxsBal, expectedEligibleVefxsBal);
        assertEq(retrievedEndingTimestamp, expectedEndingTimestamp);

        hoax(bob);
        vestedFXS.increaseAmount(3e18, 0);
        expectedEligibleVefxsBal = vestedFXS.balanceOf(bob);

        (retrievedEligibleVefxsBal, retrievedEndingTimestamp) = yieldDistributor.eligibleCurrentVeFXS(bob);

        assertEq(retrievedEligibleVefxsBal, expectedEligibleVefxsBal);
        assertEq(retrievedEndingTimestamp, expectedEndingTimestamp);

        skip(4 * WEEK_UINT256);

        hoax(bob);
        vestedFXS.increaseUnlockTime(endTimestamp + (2 * WEEK_UINT128), 0);

        expectedEligibleVefxsBal = vestedFXS.balanceOf(bob);
        (retrievedEligibleVefxsBal, retrievedEndingTimestamp) = yieldDistributor.eligibleCurrentVeFXS(bob);

        assertEq(retrievedEligibleVefxsBal, expectedEligibleVefxsBal);
        assertEq(retrievedEndingTimestamp, expectedEndingTimestamp);

        yieldDistributor.checkpointOtherUser(bob);

        expectedEndingTimestamp = endTimestamp + (2 * WEEK_UINT128);
        (retrievedEligibleVefxsBal, retrievedEndingTimestamp) = yieldDistributor.eligibleCurrentVeFXS(bob);

        assertEq(retrievedEligibleVefxsBal, expectedEligibleVefxsBal);
        assertEq(retrievedEndingTimestamp, expectedEndingTimestamp);

        skip(uint256(MAXTIME_UINT128));

        expectedEligibleVefxsBal = 0;
        (retrievedEligibleVefxsBal, retrievedEndingTimestamp) = yieldDistributor.eligibleCurrentVeFXS(bob);

        assertEq(retrievedEligibleVefxsBal, expectedEligibleVefxsBal);
        assertEq(retrievedEndingTimestamp, expectedEndingTimestamp);

        // // Have the bot update the L1VeFXSTotalSupplyOracle
        // hoax(l1VeFXSTotalSupplyOracle.botAddress());
        // l1VeFXSTotalSupplyOracle.updateInfo(94593206519519170305666435, 1713199350);
    }

    function test_LastTimeYieldApplicable() public {
        _doInitialBobLock();

        uint256 expectedLastTimeYieldApplicable = 0;

        assertEq(yieldDistributor.lastTimeYieldApplicable(), expectedLastTimeYieldApplicable);

        yieldDistributor.sync();

        yieldDistributor.toggleRewardNotifier(bob);
        yieldDistributor.notifyRewardAmount(1e15);
        yieldDistributor.setYieldRate(1e5, true);

        expectedLastTimeYieldApplicable = block.timestamp;

        assertEq(yieldDistributor.lastTimeYieldApplicable(), expectedLastTimeYieldApplicable);

        skip(1_000_000);

        expectedLastTimeYieldApplicable += 604_800;

        assertEq(yieldDistributor.lastTimeYieldApplicable(), expectedLastTimeYieldApplicable);
    }

    function test_ForgetCheckpointingAfterExpiryOfOneLock() public {
        // Warp to the start of an epoch week
        uint256 _epochStart = 604_800 * (1 + (block.timestamp / 604_800));
        _warpToAndRollOne(_epochStart);

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve to veFXS
        token.approve(address(vestedFXS), 200e18);

        // Create two locks: one ending in 1 month, another in 3 months
        uint128 _endTsTmp = uint128(block.timestamp) + uint128(((1 * 4 * (604_800)) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));
        vestedFXS.createLock(bob, 100e18, _endTsTmp);
        _endTsTmp = uint128(block.timestamp) + uint128(((3 * 4 * (604_800)) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));
        vestedFXS.createLock(bob, 100e18, _endTsTmp);

        // Bob checkpoints himself on the YD
        yieldDistributor.checkpoint();

        // Stop impersonating Bob
        vm.stopPrank();

        // Add in a weekly reward, wait a week, and check Bob's earnings again
        // Do for 3 weeks total
        for (uint256 i = 0; i < 3; i++) {
            // Approve to the YD and notify rewards
            token.approve(address(yieldDistributor), 10e18);
            yieldDistributor.notifyRewardAmount(10e18);

            // Wait a week
            _warpToAndRollOne(block.timestamp + 604_800);

            // Check earnings
            uint256 _earnings = yieldDistributor.earned(bob);
            uint256 _yield = yieldDistributor.yields(bob);
            console.log("_earnings at end of week #%s: %s", i, _earnings);
            console.log("_yield at end of week #%s: %s", i, _yield);
            assertApproxEqRel(_earnings, 10e18 * (i + 1), 0.01e18, "Bob should have earned 10 FXS per week");
        }

        // // Check eligibleCurrentVeFXS
        // {
        //     ( uint256 _eligibleVeFXS, uint _storedEndingTimestamp) = yieldDistributor.eligibleCurrentVeFXS(bob);
        //     console.log("_eligibleVeFXS: ", _eligibleVeFXS);
        //     console.log("block.timestamp: ", block.timestamp);
        //     console.log("_storedEndingTimestamp: ", _storedEndingTimestamp);
        //     assertEq(_eligibleVeFXS, 0, "Bob's eligible veFXS should now be 0 since one of his locks expired");
        // }

        // Make sure that only 10 FXS per week is being emitted
        assertApproxEqRel(yieldDistributor.getYieldForDuration(), 10e18, 0.01e18, "Yield should be 10 FXS per week");

        // Warp a few seconds before the next week
        _warpToAndRollOne(block.timestamp + 604_800 - 10);

        // Bob should have earned 30 FXS
        assertApproxEqRel(yieldDistributor.earned(bob), 30e18, 0.025e18, "Bob should have earned 30 FXS right before the end of week 4");

        // Warp into the next week
        _warpToAndRollOne(block.timestamp + 10);

        // At the start of Week 4 now
        // Bob forgets to checkpoint
        // Do nothing

        // Approve to the YD and notify rewards
        token.approve(address(yieldDistributor), 10e18);
        yieldDistributor.notifyRewardAmount(10e18);

        // Bob's earnings should be cut to ~15 FXS after the new period because he has an expired lock now
        assertApproxEqRel(yieldDistributor.earned(bob), 15e18, 0.025e18, "Bob's earnings should be cut to ~15 FXS");

        // Note Bob's earnings at the start of week 4
        uint256 _w4Earnings = yieldDistributor.earned(bob);

        // Make sure that only 10 FXS per week is being emitted
        assertApproxEqRel(yieldDistributor.getYieldForDuration(), 10e18, 0.01e18, "Yield should be 10 FXS per week");

        // Bob should still be at 15 FXS earnings
        uint256 _earnings = yieldDistributor.earned(bob);
        console.log("Earned at start of week #%s: %s", 4, _earnings);
        console.log("Yield at start of week #%s: %s", 4, yieldDistributor.yields(bob));
        assertApproxEqRel(_earnings, 15e18, 0.025e18, "Bob should still be at ~15 FXS");

        // Bob finally checkpoints himself
        hoax(bob);
        yieldDistributor.checkpoint();

        // Checkpointing alone should not have changed / recovered lost earnings
        assertEq(yieldDistributor.earned(bob), _earnings, "Checkpointing alone should not have changed / recovered lost earnings");

        // Add in a weekly reward, wait a week, and check Bob's earnings again
        // Do for 7 weeks total
        for (uint256 i = 0; i < 7; i++) {
            // Skip for the 1st loop since we already did this
            if (i > 0) {
                // Approve to the YD and notify rewards
                token.approve(address(yieldDistributor), 10e18);
                yieldDistributor.notifyRewardAmount(10e18);
            }

            // Wait a week
            _warpToAndRollOne(block.timestamp + 604_800);

            // Check earnings
            uint256 _earnings = yieldDistributor.earned(bob);
            uint256 _yield = yieldDistributor.yields(bob);
            console.log("_earnings at start of week #%s: %s", i + 5, _earnings);
            console.log("_yield at start of week #%s: %s", i + 5, _yield);
            assertApproxEqRel(_earnings, 15e18 + (10e18 * (i + 1)), 0.01e18, "Bob should have earned 10 FXS per week");
        }

        // Warp a few seconds before the next week
        _warpToAndRollOne(block.timestamp + 604_800 - 10);

        // Bob should have earned 15 + (10 * 7) = 85 FXS
        assertApproxEqRel(yieldDistributor.earned(bob), 85e18, 0.025e18, "Bob should have earned 85 FXS right before the end of week 11");

        // Bob checkpoints right in the nick of time, but still doesn't collect
        hoax(bob);
        yieldDistributor.checkpoint();

        // Warp into the next week
        _warpToAndRollOne(block.timestamp + 10);

        // Bob's rewards should not have been cut
        assertApproxEqRel(yieldDistributor.earned(bob), 85e18, 0.025e18, "Bob's rewards should not have been cut");

        // Warp into the next month
        _warpToAndRollOne(block.timestamp + (4 * 604_800));

        // Bob's rewards should still not have been cut
        assertApproxEqRel(yieldDistributor.earned(bob), 85e18, 0.025e18, "Bob's rewards should still not have been cut");
    }

    function test_EarlyMicroLockNoExtraGains() public {
        // Warp to the start of an epoch week
        uint256 _epochStart = 604_800 * (1 + (block.timestamp / 604_800));
        _warpToAndRollOne(_epochStart);

        // Impersonate Alice
        vm.startPrank(alice);

        // Approve to veFXS
        token.approve(address(vestedFXS), 10e18);

        // Alice creates one lock: an honest one ending in 1 year
        uint128 _endTsTmp = uint128(block.timestamp) + uint128(((4 * 12 * (604_800)) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));
        vestedFXS.createLock(alice, 10e18, _endTsTmp);

        // Alice checkpoints himself on the YD
        yieldDistributor.checkpoint();

        // Stop impersonating Alice
        vm.stopPrank();

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve to veFXS
        token.approve(address(vestedFXS), 1000 gwei);

        // Bob creates one lock: a nefarious tiny one ending in 11 weeks
        _endTsTmp = uint128(block.timestamp) + uint128(((1 * 11 * (604_800)) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));
        vestedFXS.createLock(bob, 1000 gwei, _endTsTmp);

        // Bob checkpoints himself on the YD
        yieldDistributor.checkpoint();

        // Stop impersonating Bob
        vm.stopPrank();

        // Add in a weekly reward, wait a week, and check Alice and Bob's earnings again
        // Do for 10 weeks total
        for (uint256 i = 0; i < 10; i++) {
            // Approve to the YD and notify rewards
            token.approve(address(yieldDistributor), 10e18);
            yieldDistributor.notifyRewardAmount(10e18);

            // Wait a week
            _warpToAndRollOne(block.timestamp + 604_800);

            // Check earnings
            uint256 _earningsAlice = yieldDistributor.earned(alice);
            uint256 _yieldAlice = yieldDistributor.yields(alice);
            uint256 _earningsBob = yieldDistributor.earned(bob);
            uint256 _yieldBob = yieldDistributor.yields(bob);
            console.log("_earningsAlice at end of week #%s: %s", i, _earningsAlice);
            console.log("_yieldAlice at end of week #%s: %s", i, _yieldAlice);
            console.log("_earningsBob at end of week #%s: %s", i, _earningsBob);
            console.log("_yieldBob at end of week #%s: %s", i, _yieldBob);
            assertApproxEqRel(_earningsAlice, 10e18 * (i + 1), 0.01e18, "Alice should have earned almost all of the 10 FXS per week");
            assertLt(_earningsBob, 1e15, "Bob should have earned barely anything");
        }

        // Make sure that only 10 FXS per week is being emitted
        assertApproxEqRel(yieldDistributor.getYieldForDuration(), 10e18, 0.01e18, "Yield should be 10 FXS per week");

        // Warp 1 minute before the next week starts
        _warpToAndRollOne(block.timestamp + 604_800 - 60);

        // Alice should have earned almost all of the 100 FXS
        assertApproxEqRel(yieldDistributor.earned(alice), 100e18, 0.025e18, "Alice should have earned almost all of the 100 FXS");

        // Bob should have earned close to nothing
        assertLt(yieldDistributor.earned(bob), 1e15, "Bob should have earned barely anything");

        // Bob attempts trickery
        // ====================================

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve to veFXS
        token.approve(address(vestedFXS), 500e18);

        // Bob creates a big lock that ends in 2 weeks
        _endTsTmp = uint128(block.timestamp) + uint128(((1 * 2 * (604_800)) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));
        vestedFXS.createLock(bob, 500e18, _endTsTmp);

        // Stop impersonating Bob
        vm.stopPrank();

        // Make sure earnings were not affected
        // ====================================

        // Alice should still have earned almost all of the 100 FXS
        assertApproxEqRel(yieldDistributor.earned(alice), 100e18, 0.025e18, "Alice should have earned almost all of the 100 FXS");

        // Bob should still have earned close to nothing
        assertLt(yieldDistributor.earned(bob), 1e15, "Bob should have earned barely anything");

        // Enter the 12th week
        // ====================================

        // Warp into the next week
        _warpToAndRollOne(block.timestamp + 60);

        // At the start of Week 4 now

        // Approve to the YD and notify rewards
        token.approve(address(yieldDistributor), 10e18);
        yieldDistributor.notifyRewardAmount(10e18);

        // Alice should still have earned almost all of the 100 FXS
        assertApproxEqRel(yieldDistributor.earned(alice), 100e18, 0.025e18, "Alice should have earned almost all of the 100 FXS");

        // Bob should still have earned close to nothing
        assertLt(yieldDistributor.earned(bob), 1e15, "Bob should have earned barely anything");
    }
}
