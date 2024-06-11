// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestMisc } from "../BaseTestMisc.t.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { OwnedV2 } from "src/contracts/Miscellany/OwnedV2.sol";
import { TimedLocker } from "src/contracts/Miscellany/TimedLocker.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_TimedLocker is BaseTestMisc {
    // Avoid stack-too-deep
    // -----------------------------
    uint256 _ttlRewardAmount;
    uint256 _aliceCollectedFXS;
    mapping(address => uint256) public _startFXS; // User -> Initial FXS balance
    mapping(address => uint256) public _endFXS; // User -> Ending FXS balance

    // Test settings
    uint256 TARGET_APR_E18 = 0.15e18;
    uint256 FXS_PRICE_E18 = 4.25e18;
    uint256 TARGET_FXB_AMOUNT_FOR_APR = 1_000_000e18;
    uint256 YEAR_SECONDS = 31_536_000;

    function TimedLockerSetup() public {
        console.log("TimedLockerSetup() called");
        super.defaultSetup();

        // Mint FXS to this address
        fxs.mint(address(this), 200_000e18);

        // Mint FXB to this address and the test users
        fxb.mint(address(this), 10_000e18);
        fxb.mint(alice, 2_000_000e18);
        fxb.mint(bob, 2_000_000e18);
        fxb.mint(claire, 2_000_000e18);
    }

    function BasicAliceSetup() public {
        // Notify rewards (1 FXS per day)
        {
            // See how many days are left in the locker
            uint256 _daysLeftE18 = ((timedLocker.periodFinish() - block.timestamp) * 1e18) / 86_400;

            // Do 1 FXS per day for this test
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _daysLeftE18;
            _ttlRewardAmount = _daysLeftE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
            console.log("Total rewards (_daysLeftE18 / 1E18): ", _daysLeftE18 / 1e18);
        }

        // Impersonate Alice
        vm.startPrank(alice);

        // Approve and stake
        fxb.approve(timedLockerAddress, 100e18);
        timedLocker.stake(100e18);

        // Wait 10 days
        _warpToAndRollOne(block.timestamp + (10 days));

        vm.stopPrank();
    }

    function test_transferOwnership() public {
        TimedLockerSetup();

        // TODO: ALSO CHECK THAT TRANSFERRING TOKENS DOESN'T CAUSE THE OLD OWNER TO LOSE REWARDS. MAKE SURE THAT IT CANNOT
        // BE GAMED WHERE THEY CAN STILL EARNED BY TRANSFERRING THE TOKEN OUT, WAITING, THEN SENDING IT BACK AND CLAIMING

        // TODO: ALSO CHECK THAT TRANSFERRING TOKENS DOESN'T CAUSE THE OLD OWNER TO LOSE REWARDS. MAKE SURE THAT IT CANNOT
        // BE GAMED WHERE THEY CAN STILL EARNED BY TRANSFERRING THE TOKEN OUT, WAITING, THEN SENDING IT BACK AND CLAIMING

        // TODO: ALSO CHECK THAT TRANSFERRING TOKENS DOESN'T CAUSE THE OLD OWNER TO LOSE REWARDS. MAKE SURE THAT IT CANNOT
        // BE GAMED WHERE THEY CAN STILL EARNED BY TRANSFERRING THE TOKEN OUT, WAITING, THEN SENDING IT BACK AND CLAIMING
    }

    function getFXSEarnings(address _user) public returns (uint256 _fxsRewards) {
        uint256[] memory _earnings = timedLocker.earned(_user);
        _fxsRewards = _earnings[0];
    }

    /// @param _startTs Timestamp to start tracking user APR from.
    /// @param _collectedFxsSinceStartTs How much FXS has already been collected since _startTs
    /// @dev BalanceOf and totalSupply (all users) must have remained the same since then
    function getUserEffectiveAPR(address _user, uint256 _startTs, uint256 _collectedFxsSinceStartTs) public returns (uint256 _userAprE18) {
        // Add already-collected FXS to the uncollected earnings
        uint256 _totalFxsEarnings = _collectedFxsSinceStartTs + getFXSEarnings(_user);

        // Calculate the elapsed time
        uint256 _timeElapsed = block.timestamp - _startTs;

        // Calculate current yield
        uint256 _fxsValuePerTknPerSecond = ((_totalFxsEarnings * FXS_PRICE_E18) / (timedLocker.balanceOf(_user) * _timeElapsed));

        // Extrapolate to 1 year for the APR
        _userAprE18 = _fxsValuePerTknPerSecond * YEAR_SECONDS;
    }

    function calcFXSNeededForTargetAPR(uint256 _targetAprE18) public returns (uint256 _currAprE18, uint256 _fxsNeeded) {
        // Fetch the ending timestamp
        uint256 _endTs = timedLocker.endingTimestamp();

        // Return 0 if the locker has already ended
        if (_endTs < block.timestamp) return (0, 0);

        // // Sync the locker
        // timedLocker.sync();

        // See how much time is left
        uint256 _timeLeft = _endTs - block.timestamp;

        // See how much FXS is left to give
        uint256 _fxsRemaining = _timeLeft * timedLocker.rewardRates(0);
        uint256 _fxsValueRemaining = (_fxsRemaining * FXS_PRICE_E18) / 1e18;

        // Calculate the current APR
        _currAprE18 = ((_fxsValueRemaining * YEAR_SECONDS * 1e18) / (timedLocker.totalSupply() * _timeLeft));

        // Calculate total FXS needed for the target APR
        uint256 _totalFxsValueNeeded = (_targetAprE18 * timedLocker.totalSupply() * _timeLeft) / (YEAR_SECONDS * 1e18);
        uint256 _totalFxsNeeded = (_totalFxsValueNeeded * 1e18) / (FXS_PRICE_E18);

        {
            // See how much time elapsed
            uint256 _timeElapsed = block.timestamp - timedLocker.deployTimestamp();

            // Print
            console.log("*** calcFXSNeededForTargetAPR ***");
            console.log("   - _timeLeft (sec): ", _timeLeft);
            console.log("   - _timeLeft (days): ", _timeLeft / 86_400);
            console.log("   - FXS balanceOf (E0): ", fxs.balanceOf(timedLockerAddress) / 1e18);
            console.log("   - _fxsRemaining (E0): ", _fxsRemaining / 1e18);
            console.log("   - _fxsValueRemaining (E0): ", _fxsValueRemaining / 1e18);
            console.log("   - _totalFxsValueNeeded (E0): ", _totalFxsValueNeeded / 1e18);
            console.log("   - _totalFxsNeeded (E0): ", _totalFxsNeeded / 1e18);
            console.log("   - totalSupply (E18): ", timedLocker.totalSupply());
            console.log("   - totalSupply (E0): ", timedLocker.totalSupply() / 1e18);
            console.log("*********************************");
        }

        // Return the amount of FXS missing for the target APR
        if (_totalFxsNeeded < _fxsRemaining) return (_currAprE18, 0);
        else _fxsNeeded = _totalFxsNeeded - _fxsRemaining;
    }

    function markInitialFXSBalances() public {
        _startFXS[timedLockerAddress] = fxs.balanceOf(timedLockerAddress);
        _startFXS[alice] = fxs.balanceOf(alice);
        _startFXS[bob] = fxs.balanceOf(bob);
    }

    function markFinalFXSBalances() public {
        _endFXS[timedLockerAddress] = fxs.balanceOf(timedLockerAddress);
        _endFXS[alice] = fxs.balanceOf(alice);
        _endFXS[bob] = fxs.balanceOf(bob);
    }

    function checkRewardTotalEmissions() public {
        // See the total amount of FXS collected by users
        uint256 _fxsCollectedByUsers = _endFXS[alice] - _startFXS[alice];
        _fxsCollectedByUsers += (_endFXS[bob] - _startFXS[bob]);

        // FXS sent out should = FXS collected
        console.log("_ttlRewardAmount: ", _ttlRewardAmount);
        console.log("_fxsCollectedByUsers: ", _fxsCollectedByUsers);
        assertApproxEqRel(_ttlRewardAmount, _fxsCollectedByUsers, 0.001e18, "FXS out should = user earnings");

        // Note any over or under emission
        if (_ttlRewardAmount > _fxsCollectedByUsers) console.log("[UNDEREMISSION]: ", _ttlRewardAmount - _fxsCollectedByUsers);
        else if (_fxsCollectedByUsers > _ttlRewardAmount) console.log("[OVEREMISSION]: ", _fxsCollectedByUsers - _ttlRewardAmount);
    }

    function test_transferRewardTracking() public {
        TimedLockerSetup();

        // Notify rewards (1 FXS per day)
        {
            // See how many days are left in the locker
            uint256 _daysLeftE18 = ((timedLocker.periodFinish() - block.timestamp) * 1e18) / 86_400;

            // Do 1 FXS per day for this test
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _daysLeftE18;
            _ttlRewardAmount = _daysLeftE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
            console.log("Total rewards (_daysLeftE18 / 1E18): ", _daysLeftE18 / 1e18);
        }

        // Impersonate Alice
        vm.startPrank(alice);

        // Approve and stake
        fxb.approve(timedLockerAddress, 100e18);
        timedLocker.stake(100e18);

        // Wait 10 days
        _warpToAndRollOne(block.timestamp + (10 days));

        // Alice should have earned 10 FXS
        assertApproxEqRel(getFXSEarnings(alice), 10e18, 0.01e18, "Alice should have earned 10 FXS");

        // Alice transfers half her tokens to Bob
        timedLocker.transfer(bob, 50e18);

        // Alice should still have the 10 FXS earnings
        assertApproxEqRel(getFXSEarnings(alice), 10e18, 0.01e18, "Alice should still have earned 10 FXS");

        // Bob should not have any earnings
        assertEq(getFXSEarnings(bob), 0, "Bob should have no earnings");

        // Wait 10 days
        _warpToAndRollOne(block.timestamp + (10 days));

        // Alice should have earned an extra 5 FXS, for 15 FXS total
        assertApproxEqRel(getFXSEarnings(alice), 15e18, 0.01e18, "Alice should have earned 15 FXS");

        // Bob should have earned 5 FXS
        assertApproxEqRel(getFXSEarnings(bob), 5e18, 0.01e18, "Bob should have earned 5 FXS");

        // Stop the prank
        vm.stopPrank();

        // Impersonate Bob
        vm.startPrank(bob);

        // Bob transfers all of his tokens back to Alice
        timedLocker.transfer(alice, 50e18);

        // Alice should still have earned 15 FXS
        assertApproxEqRel(getFXSEarnings(alice), 15e18, 0.01e18, "Alice should still have earned 15 FXS");

        // Bob should have still have earned 5 FXS
        assertApproxEqRel(getFXSEarnings(bob), 5e18, 0.01e18, "Bob should still have earned 5 FXS");

        // Stop the prank
        vm.stopPrank();

        // Wait 10 days
        _warpToAndRollOne(block.timestamp + (10 days));

        // Alice should now have earned 25 FXS
        assertApproxEqRel(getFXSEarnings(alice), 25e18, 0.01e18, "Alice should now have earned 25 FXS");

        // Bob should have still have earned 5 FXS
        assertApproxEqRel(getFXSEarnings(bob), 5e18, 0.01e18, "Bob should have still have earned 5 FXS");
    }

    function test_APRTargeting() public {
        TimedLockerSetup();

        // Mark initial FXS balances
        markInitialFXSBalances();

        // Notify rewards to target TARGET_APR_E18 using FXS_PRICE_E18 and TARGET_FXB_AMOUNT_FOR_APR
        console.log("<<< Put rewards in the TimedLocker >>>");
        {
            // See how many days are left in the locker
            uint256 _daysLeftE6 = ((timedLocker.periodFinish() - block.timestamp) * 1e6) / 86_400;

            // Calculate the amount of FXS needed assuming TARGET_FXB_AMOUNT_FOR_APR is staked
            uint256 _fxsNeededAllTimeE18 = (TARGET_APR_E18 * _daysLeftE6 * TARGET_FXB_AMOUNT_FOR_APR) / (365.25e6 * FXS_PRICE_E18);
            uint256 _fxsNeededOneYearTimeE18 = (TARGET_APR_E18 * TARGET_FXB_AMOUNT_FOR_APR) / (FXS_PRICE_E18);
            console.log("Days left: ", _daysLeftE6 / 1e6);
            console.log("FXS needed [Total] for %s%% APR: %s [$%s]", (TARGET_APR_E18 * 100) / 1e18, _fxsNeededAllTimeE18 / 1e18, (_fxsNeededAllTimeE18 * FXS_PRICE_E18) / 1e36);
            console.log("FXS needed [1-year only] for %s%% APR: %s [$%s]", (TARGET_APR_E18 * 100) / 1e18, _fxsNeededOneYearTimeE18 / 1e18, (_fxsNeededOneYearTimeE18 * FXS_PRICE_E18) / 1e36);

            // Feed the locker
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _fxsNeededAllTimeE18;
            _ttlRewardAmount = _fxsNeededAllTimeE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
        }

        // Approve and stake as Alice
        console.log("<<< Alice stakes TARGET_FXB_AMOUNT_FOR_APR >>>");
        hoax(alice);
        fxb.approve(timedLockerAddress, TARGET_FXB_AMOUNT_FOR_APR);
        hoax(alice);
        timedLocker.stake(TARGET_FXB_AMOUNT_FOR_APR);

        // Wait 10 days
        console.log("<<< Wait 10 days >>>");
        _warpToAndRollOne(block.timestamp + (10 days));

        // Check that Alice's APR matches the target
        console.log("<<< Check Alice's APR >>>");
        {
            uint256 _currAPR = getUserEffectiveAPR(alice, block.timestamp - (10 days), 0);
            uint256 _currEarnings = getFXSEarnings(alice);
            console.log("Alice's current effective APR: %s", _currAPR);
            console.log("Alice's FXS earnings: %s [$%s]", _currEarnings / 1e18, (_currEarnings * FXS_PRICE_E18) / 1e36);

            // Alice's APR should be near the target since she staked TARGET_FXB_AMOUNT_FOR_APR
            assertApproxEqRel(_currAPR, TARGET_APR_E18, 0.01e18, "Alice's APR should be near the target");
        }

        // Alice claims rewards
        {
            hoax(alice);
            uint256[] memory _rtnRewards = timedLocker.getReward(alice);
            _aliceCollectedFXS += _rtnRewards[0];
        }

        // Bob enters and lowers the APR
        console.log("<<< Bob stakes TARGET_FXB_AMOUNT_FOR_APR >>>");
        hoax(bob);
        fxb.approve(timedLockerAddress, TARGET_FXB_AMOUNT_FOR_APR);
        hoax(bob);
        timedLocker.stake(TARGET_FXB_AMOUNT_FOR_APR);

        // Wait 10 days
        console.log("<<< Wait 10 days >>>");
        _warpToAndRollOne(block.timestamp + (10 days));

        // APR should have been cut in half because of Bob
        // Alice's effective APR should be the average between full and half so ~11.25%
        console.log("<<< Check Alice's APR again. Should be ~11.25% >>>");
        {
            uint256 _currAPR = getUserEffectiveAPR(alice, block.timestamp - (20 days), _aliceCollectedFXS);
            uint256 _currEarnings = getFXSEarnings(alice);
            console.log("Alice's current effective APR: %s", _currAPR);
            console.log("Alice's FXS earnings: %s [$%s]", _currEarnings / 1e18, (_currEarnings * FXS_PRICE_E18) / 1e36);

            // Alice's APR should be ~11.25% (average of 15% and 7.5%)
            assertApproxEqRel(_currAPR, (TARGET_APR_E18 + (TARGET_APR_E18 / 2)) / 2, 0.01e18, "Alice's APR should be close to ~11.25%");
        }

        // Calculate how much more FXS you need to bring the APR back up
        console.log("<<< Calculate how much more FXS you need to bring the APR back up to target, then feed >>>");
        {
            // Do the calculation
            (uint256 _currAPR, uint256 _fxsNeeded) = calcFXSNeededForTargetAPR(TARGET_APR_E18);
            console.log("Current APR [before feeding]: %s", _currAPR);
            console.log("Target APR [before feeding]: %s", TARGET_APR_E18);
            console.log("FXS needed to bring up to target APR (E0) [1]: %s", _fxsNeeded / 1e18);

            // Feed more FXS rewards into the locker
            // Feed the locker
            console.log("<<< Feeding FXS to the locker >>>");
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _fxsNeeded;
            _ttlRewardAmount += _fxsNeeded;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);

            // Re-check the APR after feeding
            console.log("<<< Re-check the APR after feeding >>>");

            // Do the calculation
            (_currAPR, _fxsNeeded) = calcFXSNeededForTargetAPR(TARGET_APR_E18);
            console.log("Current APR [after feeding]: %s", _currAPR);
            console.log("Target APR [after feeding]: %s", TARGET_APR_E18);
            console.log("FXS needed to bring up to target APR (E0) [2]: %s", _fxsNeeded / 1e18);

            // Post feeding APR should be target APR
            assertApproxEqRel(_currAPR, TARGET_APR_E18, 0.01e18, "Post feeding APR should be target APR");
        }

        // Wait 10 days
        console.log("<<< Wait 10 days >>>");
        _warpToAndRollOne(block.timestamp + (10 days));

        console.log("<<< Check Alice's APR again >>>");
        {
            uint256 _currAPR = getUserEffectiveAPR(alice, block.timestamp - (30 days), _aliceCollectedFXS);
            uint256 _currEarnings = getFXSEarnings(alice);
            console.log("Alice's current effective APR: %s", _currAPR);
            console.log("Alice's FXS earnings: %s [$%s]", _currEarnings / 1e18, (_currEarnings * FXS_PRICE_E18) / 1e36);

            // Should be about 12.5% (15% for 10 days, 7.5% for 10 days after Bob entered, 15% for 10 days after FXS refill)
            // (10 days * (15 + 7.5 + 15)) / 30 days = 12.5
            assertApproxEqRel(_currAPR, 0.125e18, 0.01e18, "Alice's APR should be around 12.5%");
        }

        console.log("<<< Check Bob's APR >>>");
        {
            uint256 _currAPR = getUserEffectiveAPR(bob, block.timestamp - (20 days), 0);
            uint256 _currEarnings = getFXSEarnings(bob);
            console.log("Bob's current effective APR: %s", _currAPR);
            console.log("Bob's FXS earnings: %s [$%s]", _currEarnings / 1e18, (_currEarnings * FXS_PRICE_E18) / 1e36);

            // Should be about 11.5% (7.5% for 10 days after he entered, 15% for 10 days after FXS refill)
            // (10 days * (15 + 7.5)) / 20 days = 11.25
            assertApproxEqRel(_currAPR, 0.1125e18, 0.01e18, "Bob's APR should be around 11.25%");
        }

        // Check the current APR
        console.log("<<< Verify that the current APR matches the target >>>");
        {
            // Do the calculation
            (uint256 _currAPR, uint256 _fxsNeeded) = calcFXSNeededForTargetAPR(TARGET_APR_E18);
            console.log("Current APR: %s", _currAPR);
            console.log("Target APR: %s", TARGET_APR_E18);
            console.log("FXS needed to bring up to target APR: %s", _fxsNeeded);

            // Should be on target with no FXS needed
            assertApproxEqRel(_currAPR, TARGET_APR_E18, 0.01e18, "Current APR should match target APR");
            assertApproxEqAbs(_fxsNeeded, 0, 0.01e18, "No FXS should be needed to match the target APR");
        }

        // Warp past the end
        console.log("<<< Warp past the end >>>");
        _warpToAndRollOne(block.timestamp + (900 days));

        console.log("<<< Alice and Bob both withdraw and collect their rewards >>>");
        {
            uint256 _aliceBalance = timedLocker.balanceOf(alice);
            uint256 _bobBalance = timedLocker.balanceOf(bob);
            console.log("Alice locker token balance: ", _aliceBalance);
            console.log("Bob locker token balance: ", _bobBalance);
            hoax(alice);
            console.log("<<<    - Alice withdraws >>>");
            timedLocker.withdraw(_aliceBalance, true);
            hoax(bob);
            console.log("<<<    - Bob withdraws >>>");
            timedLocker.withdraw(_bobBalance, true);
        }

        // Note final FXS balances
        markFinalFXSBalances();

        // Check that FXS was not under or overemitted
        checkRewardTotalEmissions();
    }

    function test_miscPauses() public {
        TimedLockerSetup();

        // Setup rewards and Alice
        BasicAliceSetup();

        // Random user Claire should not be able to pause reward collection
        hoax(claire);
        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        timedLocker.toggleRewardsCollection();

        // Pause reward collection
        timedLocker.toggleRewardsCollection();

        // Alice fails to collect rewards
        vm.expectRevert(TimedLocker.RewardCollectionIsPaused.selector);
        hoax(alice);
        timedLocker.getReward(alice);

        // Resume reward collection
        timedLocker.toggleRewardsCollection();

        // Alice can collect rewards now
        hoax(alice);
        timedLocker.getReward(alice);

        // Random user Claire should not be able to pause staking
        hoax(claire);
        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        timedLocker.toggleStaking();

        // Pause staking
        timedLocker.toggleStaking();

        // Alice approves and tries to stake (should fail)
        hoax(alice);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(alice);
        vm.expectRevert(TimedLocker.StakingPaused.selector);
        timedLocker.stake(1e18);

        // Resume staking
        timedLocker.toggleStaking();

        // Alice should be able to stake now
        hoax(alice);
        timedLocker.stake(1e18);

        // Random user Claire should not be able to disable bulkSyncEarnedUsers
        hoax(claire);
        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        timedLocker.toggleExternalSyncEarning();

        // Disable bulkSyncEarnedUsers
        timedLocker.toggleExternalSyncEarning();

        // Alice fails to be able to bulkSyncEarnedUsers
        {
            address[] memory _usersToSync = new address[](1);
            _usersToSync[0] = alice;
            hoax(alice);
            vm.expectRevert(TimedLocker.ExternalSyncEarningPaused.selector);
            timedLocker.bulkSyncEarnedUsers(_usersToSync);
        }

        // Re-enable bulkSyncEarnedUsers
        timedLocker.toggleExternalSyncEarning();

        // Alice is able to bulkSyncEarnedUsers
        {
            address[] memory _usersToSync = new address[](1);
            _usersToSync[0] = alice;
            hoax(alice);
            timedLocker.bulkSyncEarnedUsers(_usersToSync);
        }

        // Warp past the end
        console.log("<<< Warp past the end >>>");
        _warpToAndRollOne(block.timestamp + (900 days));

        // Random user Claire should not be able to pause withdrawals
        hoax(claire);
        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        timedLocker.toggleWithdrawals();

        // Pause withdrawals
        timedLocker.toggleWithdrawals();

        // Alice should not be able to withdraw
        hoax(alice);
        vm.expectRevert(TimedLocker.WithdrawalsPaused.selector);
        timedLocker.withdraw(1e18, true);

        // Resume withdrawals
        timedLocker.toggleWithdrawals();

        // Alice should now be able to withdraw
        hoax(alice);
        timedLocker.withdraw(1e18, true);
    }

    function test_withdrawalOnlyShutdown() public {
        TimedLockerSetup();

        // Setup rewards and Alice
        BasicAliceSetup();

        // Initiate the withdrawal-only shutdown
        timedLocker.initiateWithdrawalOnlyShutdown();

        // Alice approves and tries to stake (should fail)
        hoax(alice);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(alice);
        vm.expectRevert(TimedLocker.OnlyWithdrawalsAllowed.selector);
        timedLocker.stake(1e18);

        // Alice fails to collect rewards
        vm.expectRevert(TimedLocker.OnlyWithdrawalsAllowed.selector);
        hoax(alice);
        timedLocker.getReward(alice);

        // Alice fails to be able to bulkSyncEarnedUsers
        {
            address[] memory _usersToSync = new address[](1);
            _usersToSync[0] = alice;
            hoax(alice);
            vm.expectRevert(TimedLocker.ExternalSyncEarningPaused.selector);
            timedLocker.bulkSyncEarnedUsers(_usersToSync);
        }

        // Alice SHOULD NOT be able to withdraw WITH reward collection
        hoax(alice);
        vm.expectRevert(TimedLocker.OnlyWithdrawalsAllowed.selector);
        timedLocker.withdraw(1e18, true);

        // Alice SHOULD be able to withdraw WITHOUT reward collection
        hoax(alice);
        timedLocker.withdraw(1e18, false);
    }

    function test_unlockStakes() public {
        TimedLockerSetup();

        // Setup rewards and Alice
        BasicAliceSetup();

        // Alice should NOT be able to withdraw because it is too early
        hoax(alice);
        vm.expectRevert(TimedLocker.LockerStillActive.selector);
        timedLocker.withdraw(1e18, true);

        // Random user Claire should not be able to unlock stakes
        hoax(claire);
        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        timedLocker.unlockStakes();

        // Unlock all stakes
        timedLocker.unlockStakes();

        // Alice should be able to withdraw because stakes are unlocked
        hoax(alice);
        timedLocker.withdraw(1e18, true);

        // Alice should not be able to stake more
        hoax(alice);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(alice);
        vm.expectRevert(TimedLocker.StakesAreUnlocked.selector);
        timedLocker.stake(1e18);

        // Pause reward collection
        timedLocker.toggleRewardsCollection();

        // Alice SHOULD NOT be able to withdraw and collect rewards simultaneously
        hoax(alice);
        vm.expectRevert(TimedLocker.RewardCollectionIsPaused.selector);
        timedLocker.withdraw(1e18, true);

        // Alice SHOULD be able to withdraw and forego rewards
        hoax(alice);
        timedLocker.withdraw(1e18, false);
    }

    function test_toggleRewardNotifier() public {
        TimedLockerSetup();

        // Setup rewards and Alice
        BasicAliceSetup();

        // Mint FXS to Claire
        fxs.mint(claire, 100e18);

        // Claire should not be able to notify rewards because she is not an approved notifier
        hoax(claire);
        fxs.approve(timedLockerAddress, 1e18);
        hoax(claire);
        uint256[] memory _rewardAmts = new uint256[](1);
        _rewardAmts[0] = 1e18;
        vm.expectRevert(TimedLocker.SenderNotRewarder.selector);
        timedLocker.notifyRewardAmounts(_rewardAmts);

        // Random user Claire should not be able to add herself as a reward notifier
        hoax(claire);
        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        timedLocker.toggleRewardNotifier(claire);

        // Enable Claire as a reward notifier as the owner
        timedLocker.toggleRewardNotifier(claire);

        // Claire should now be able to notify rewards
        hoax(claire);
        timedLocker.notifyRewardAmounts(_rewardAmts);

        // Warp past the end
        console.log("<<< Warp past the end >>>");
        _warpToAndRollOne(block.timestamp + (900 days));

        // Claire should not be able to notify rewards because the locker has ended
        hoax(claire);
        vm.expectRevert(TimedLocker.LockerHasEnded.selector);
        timedLocker.notifyRewardAmounts(_rewardAmts);
    }

    function test_recoverERC20() public {
        TimedLockerSetup();

        // Setup rewards and Alice
        BasicAliceSetup();

        // Random user Claire should not be able to recover tokens
        hoax(claire);
        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        timedLocker.recoverERC20(address(fxs), 1e18);

        // Owner should be able to recover tokens
        timedLocker.recoverERC20(address(fxs), 1e18);
    }

    function test_rewardBoundaryCornerCasesOne() public {
        TimedLockerSetup();

        // Notify rewards (1 FXS per day)
        {
            // See how many days are left in the locker
            uint256 _daysLeftE18 = ((timedLocker.periodFinish() - block.timestamp) * 1e18) / 86_400;

            // Do 1 FXS per day for this test
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _daysLeftE18;
            _ttlRewardAmount = _daysLeftE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
            console.log("Total rewards (_daysLeftE18 / 1E18): ", _daysLeftE18 / 1e18);
        }

        // Alice stakes 1 FXB
        hoax(alice);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(alice);
        timedLocker.stake(1e18);

        // Bob stakes 1 FXB
        hoax(bob);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(bob);
        timedLocker.stake(1e18);

        // Warp 100 days
        console.log("<<< Warp 100 days >>>");
        _warpToAndRollOne(block.timestamp + (100 days));

        // Alice stakes 1000 FXB
        hoax(alice);
        fxb.approve(timedLockerAddress, 1000e18);
        hoax(alice);
        timedLocker.stake(1000e18);

        // Alice should not have earned anything more than bob
        {
            uint256 _aliceEarnings = getFXSEarnings(alice);
            console.log("Alice earnings: %s FXS", _aliceEarnings);
            console.log("Alice earnings (E0): %s FXS", _aliceEarnings / 1e18);
            assertApproxEqRel(_aliceEarnings, 50e18, 0.01e18, "Alice should have earned 50 FXS");
            uint256 _bobEarnings = getFXSEarnings(bob);
            console.log("Bob earnings: %s FXS", _bobEarnings);
            console.log("Bob earnings (E0): %s FXS", _bobEarnings / 1e18);
            assertApproxEqRel(_bobEarnings, 50e18, 0.01e18, "Bob should have earned 50 FXS");
            assertEq(_aliceEarnings, _bobEarnings, "Alice should not have earned anything more than bob");
        }
    }

    function test_rewardBoundaryCornerCasesTwo() public {
        TimedLockerSetup();

        // Notify rewards (1 FXS per day)
        {
            // See how many days are left in the locker
            uint256 _daysLeftE18 = ((timedLocker.periodFinish() - block.timestamp) * 1e18) / 86_400;

            // Do 1 FXS per day for this test
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _daysLeftE18;
            _ttlRewardAmount = _daysLeftE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
            console.log("Total rewards (_daysLeftE18 / 1E18): ", _daysLeftE18 / 1e18);
        }

        // Alice stakes 1 FXB
        hoax(alice);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(alice);
        timedLocker.stake(1e18);

        // Bob stakes 1 FXB
        hoax(bob);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(bob);
        timedLocker.stake(1e18);

        // Warp 100 days
        console.log("<<< Warp 100 days >>>");
        _warpToAndRollOne(block.timestamp + (100 days));

        // Notify extra rewards (1 FXS per day additional)
        console.log("<<< Add in some extra rewards >>>");
        {
            // See how many days are left in the locker
            uint256 _daysLeftE18 = ((timedLocker.periodFinish() - block.timestamp) * 1e18) / 86_400;

            // Do 1 FXS per day for this test
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _daysLeftE18;
            _ttlRewardAmount += _daysLeftE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
            console.log("Total extra rewards (_daysLeftE18 / 1E18): ", _daysLeftE18 / 1e18);
        }

        // Alice stakes 1000 FXB
        hoax(alice);
        fxb.approve(timedLockerAddress, 1000e18);
        hoax(alice);
        timedLocker.stake(1000e18);

        // Alice should not have earned anything more than Bob
        {
            uint256 _aliceEarnings = getFXSEarnings(alice);
            console.log("Alice earnings: %s FXS", _aliceEarnings);
            console.log("Alice earnings (E0): %s FXS", _aliceEarnings / 1e18);
            assertApproxEqRel(_aliceEarnings, 50e18, 0.01e18, "Alice should have earned 50 FXS");
            uint256 _bobEarnings = getFXSEarnings(bob);
            console.log("Bob earnings: %s FXS", _bobEarnings);
            console.log("Bob earnings (E0): %s FXS", _bobEarnings / 1e18);
            assertApproxEqRel(_bobEarnings, 50e18, 0.01e18, "Bob should have earned 50 FXS");
            assertEq(_aliceEarnings, _bobEarnings, "Alice should not have earned anything more than bob");
        }
    }

    function test_rewardBoundaryCornerCasesThree() public {
        TimedLockerSetup();

        // Notify rewards (1 FXS per day)
        {
            // See how many days are left in the locker
            uint256 _daysLeftE18 = ((timedLocker.periodFinish() - block.timestamp) * 1e18) / 86_400;

            // Do 1 FXS per day for this test
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _daysLeftE18;
            _ttlRewardAmount = _daysLeftE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
            console.log("Total rewards (_daysLeftE18 / 1E18): ", _daysLeftE18 / 1e18);
        }

        // Alice stakes 1 FXB
        hoax(alice);
        fxb.approve(timedLockerAddress, 1e18);
        hoax(alice);
        timedLocker.stake(1e18);

        // Bob stakes 100 FXB
        hoax(bob);
        fxb.approve(timedLockerAddress, 100e18);
        hoax(bob);
        timedLocker.stake(100e18);

        // Warp 100 days
        console.log("<<< Warp 100 days >>>");
        _warpToAndRollOne(block.timestamp + (100 days));

        // Notify extra rewards (1 FXS per day additional)
        console.log("<<< Add in some extra rewards >>>");
        {
            // See how many days are left in the locker
            uint256 _daysLeftE18 = ((timedLocker.periodFinish() - block.timestamp) * 1e18) / 86_400;

            // Do 1 FXS per day for this test
            uint256[] memory _rewardAmts = new uint256[](1);
            _rewardAmts[0] = _daysLeftE18;
            _ttlRewardAmount += _daysLeftE18;
            fxs.approve(timedLockerAddress, _rewardAmts[0]);
            timedLocker.notifyRewardAmounts(_rewardAmts);
            console.log("Total extra rewards (_daysLeftE18 / 1E18): ", _daysLeftE18 / 1e18);
        }

        // Warp right before the locker expires
        console.log("<<< Warp right before the locker expires >>>");
        _warpToAndRollOne(timedLocker.periodFinish() - 10);

        // Alice stakes 1000000 FXB
        hoax(alice);
        fxb.approve(timedLockerAddress, 1_000_000e18);
        hoax(alice);
        timedLocker.stake(1_000_000e18);

        // Alice's late stake should not have inflated her earnings
        {
            uint256 _aliceEarnings = getFXSEarnings(alice);
            console.log("Alice earnings: %s FXS", _aliceEarnings);
            console.log("Alice earnings (E0): %s FXS", _aliceEarnings / 1e18);
            assertApproxEqRel(_aliceEarnings, (_ttlRewardAmount * 1e18) / (1e18 + 100e18), 0.01e18, "Alice should have earned about 1% of the total rewards");
            uint256 _bobEarnings = getFXSEarnings(bob);
            console.log("Bob earnings: %s FXS", _bobEarnings);
            console.log("Bob earnings (E0): %s FXS", _bobEarnings / 1e18);
            assertApproxEqRel(_bobEarnings, (_ttlRewardAmount * 100e18) / (1e18 + 100e18), 0.01e18, "Bob should have earned about 99% of the total rewards");
        }
    }

    function test_cap() public {
        TimedLockerSetup();

        // Setup rewards and Alice
        BasicAliceSetup();

        // Check the rewards remaining (should be initial total - ((1 FXS / day) * 10 days))
        uint256[] memory _rtnRewardsRemaining = timedLocker.getRewardsRemaining();
        assertApproxEqRel(_ttlRewardAmount - 10e18, _rtnRewardsRemaining[0], 0.01e18, "getRewardsRemaining should be initial - 10 FXS");
    }

    function test_rewardsRemaining() public {
        TimedLockerSetup();

        // Setup rewards and Alice
        BasicAliceSetup();

        // Give Alice a lot of FXB
        fxb.mint(alice, 10_000_000e18);

        // See how much left you can lock
        uint256 _lockableRemaining = timedLocker.availableToLock();

        // Alice SHOULD NOT be able to lock more than the cap
        hoax(alice);
        fxb.approve(timedLockerAddress, _lockableRemaining + 1);
        hoax(alice);
        vm.expectRevert(TimedLocker.Capped.selector);
        timedLocker.stake(_lockableRemaining + 1);

        // Alice SHOULD be able to lock up to the cap
        hoax(alice);
        timedLocker.stake(_lockableRemaining);
    }
}
