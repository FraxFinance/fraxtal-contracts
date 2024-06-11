// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "frax-std/FraxTest.sol";
import { BaseTestMisc } from "../BaseTestMisc.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { OwnedV2 } from "src/contracts/Miscellany/OwnedV2.sol";
import { TimedLocker } from "src/contracts/Miscellany/TimedLocker.sol";

contract Fuzz_Test_TimedLocker is BaseTestMisc {
    // Test constants
    // -----------------------------
    uint256 DAY = 86_400;

    // Avoid stack-too-deep
    // -----------------------------
    address[3] _userAddrs;
    mapping(address => bool) public _tmpSkip1stRewardCollection; // User -> Skip 1st reward collection
    mapping(address => bool) public _tmpBulkSyncEarnedUsers; // User -> If they should be syncEarned in the middle of the test
    mapping(address => bool) public _tmpLateWithdrawal; // User -> Withdraw late after expiry
    mapping(address => bool) public _tmpCollectRewardsOnWithdrawal; // User -> Collect rewards on withdrawal
    uint256 _ttlRewardAmount;
    uint256 _tmpEarnings;
    uint256 _ttlRewardsCollected;

    function setUp() public {
        defaultSetup();

        // Mint FXS to this address
        fxs.mint(address(this), 10_000e18);

        // Mint FXB to this address and the test users
        fxb.mint(address(this), 10_000e18);
        fxb.mint(alice, 1000e18);
        fxb.mint(bob, 1000e18);
        fxb.mint(claire, 1000e18);

        // Misc test setup
        _userAddrs = [alice, bob, claire];
    }

    function printInfo(string memory _printTitle) public {
        // Print the title
        console.log(_printTitle);

        // Check status
        printStatus();

        // // Alice
        // _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(alice);
        // _actualVeFXS = vestedFXS.balanceOf(alice);
        // console.log("Alice expected veFXS balance:", _expectedVeFXS);
        // console.log("Alice actual veFXS balance:", _actualVeFXS);

        // // Bob
        // _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(bob);
        // _actualVeFXS = vestedFXS.balanceOf(bob);
        // console.log("Bob expected veFXS balance:", _expectedVeFXS);
        // console.log("Bob actual veFXS balance:", _actualVeFXS);

        // // Claire
        // _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(claire);
        // _actualVeFXS = vestedFXS.balanceOf(claire);
        // console.log("Claire expected veFXS balance:", _expectedVeFXS);
        // console.log("Claire actual veFXS balance:", _actualVeFXS);
    }

    function printStatus() public {
        // console.log("---------- YD ----------");
        // console.log("YD: fractionParticipating", yieldDistributor.fractionParticipating());
        // console.log("YD: ttlCombinedVeFXSTotalSupply", yieldDistributor.ttlCombinedVeFXSTotalSupply());
        // console.log("YD: lastTimeYieldApplicable", yieldDistributor.lastTimeYieldApplicable());
        // console.log("YD: yieldPerVeFXS", yieldDistributor.yieldPerVeFXS());
        // console.log("YD: getYieldForDuration", yieldDistributor.getYieldForDuration());
    }

    function testFuzz_SimpleVaulting(uint256[3] memory _1stLockAmounts, uint256[3] memory _warpTimes, uint256[3] memory _2ndLockAmounts, bool[13] memory _miscBools) public {
        printInfo("======================== BOUND FUZZ INPUTS ========================");
        // _1stLockAmounts
        for (uint256 i = 0; i < _1stLockAmounts.length; i++) {
            _1stLockAmounts[i] = bound(_1stLockAmounts[i], 1000 gwei, 100e18);
        }

        // _warpTimes
        for (uint256 i = 0; i < _warpTimes.length; i++) {
            _warpTimes[i] = bound(_warpTimes[i], 0, 2 * 365 * DAY);
        }

        // _2ndLockAmounts
        for (uint256 i = 0; i < _2ndLockAmounts.length; i++) {
            _2ndLockAmounts[i] = bound(_2ndLockAmounts[i], 1000 gwei, 100e18);
        }

        // Misc bools
        {
            // Skip 1st reward collection
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                _tmpSkip1stRewardCollection[_userAddrs[i]] = _miscBools[i];
            }

            // Whether to bulkSyncEarnedUsers
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                _tmpBulkSyncEarnedUsers[_userAddrs[i]] = _miscBools[i + _userAddrs.length];
            }

            // Late withdrawal
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                _tmpLateWithdrawal[_userAddrs[i]] = _miscBools[i + (2 * _userAddrs.length)];
            }

            // Collect rewards on withdrawal
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                _tmpCollectRewardsOnWithdrawal[_userAddrs[i]] = _miscBools[i + (3 * _userAddrs.length)];
            }
        }

        printInfo("======================== PRINT FUZZ VARIABLES ========================");

        // Alice
        console.log("------------------------ ALICE ------------------------");
        {
            // Amounts
            console.log("_1stLockAmounts: ", _1stLockAmounts[0]);
            console.log("_2ndLockAmounts: ", _2ndLockAmounts[0]);

            // Bools
            console.log("_tmpSkip1stRewardCollection: ", _tmpSkip1stRewardCollection[_userAddrs[0]]);
            console.log("_tmpLateWithdrawal: ", _tmpLateWithdrawal[_userAddrs[0]]);
            console.log("_tmpCollectRewardsOnWithdrawal: ", _tmpCollectRewardsOnWithdrawal[_userAddrs[0]]);
        }

        // Bob
        console.log("------------------------ BOB ------------------------");
        {
            // Amounts
            console.log("_1stLockAmounts: ", _1stLockAmounts[1]);
            console.log("_2ndLockAmounts: ", _2ndLockAmounts[1]);

            // Bools
            console.log("_tmpSkip1stRewardCollection: ", _tmpSkip1stRewardCollection[_userAddrs[1]]);
            console.log("_tmpLateWithdrawal: ", _tmpLateWithdrawal[_userAddrs[1]]);
            console.log("_tmpCollectRewardsOnWithdrawal: ", _tmpCollectRewardsOnWithdrawal[_userAddrs[1]]);
        }

        // Claire
        console.log("------------------------ CLAIRE ------------------------");
        {
            // Amounts
            console.log("_1stLockAmounts: ", _1stLockAmounts[2]);
            console.log("_2ndLockAmounts: ", _2ndLockAmounts[2]);

            // Bools
            console.log("_tmpSkip1stRewardCollection: ", _tmpSkip1stRewardCollection[_userAddrs[2]]);
            console.log("_tmpLateWithdrawal: ", _tmpLateWithdrawal[_userAddrs[2]]);
            console.log("_tmpCollectRewardsOnWithdrawal: ", _tmpCollectRewardsOnWithdrawal[_userAddrs[2]]);
        }
        console.log("------------------------");

        printInfo("======================== NOTIFY REWARD ========================");
        console.log("<<< Put rewards in the TimedLocker >>>");

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

        printInfo("======================== CREATE STAKES ========================");

        // Check status
        printStatus();

        // Create locks
        console.log("<<< Creating initial stakes >>>");
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Impersonate the user
            vm.startPrank(_theUser);

            // Approve and stake
            fxb.approve(timedLockerAddress, _1stLockAmounts[i]);
            timedLocker.stake(_1stLockAmounts[i]);

            vm.stopPrank();
        }

        printInfo("======================== WARPING 3.5 DAYS AND CHECKING EARNINGS ========================");

        // Warp ahead 3.5 days
        _warpToAndRollOne(block.timestamp + (3.5 days));

        // See how much everyone earned. The sum should be 3.5 FXS
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check earnings
                uint256[] memory _earnings = timedLocker.earned(_theUser);
                uint256 _rewards0 = timedLocker.rewards(_theUser, 0);
                console.log("Earned: ", _earnings[0]);
                console.log("Rewards0: ", _rewards0);
                _earnedSum += _earnings[0];

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            assertApproxEqRel(_earnedSum, 3.5e18, 0.01e18, "Earnings should sum to half of notifyRewardAmount");
        }

        printInfo("======================== SOME PEOPLE COLLECT ========================");

        // Various people collect, or don't
        {
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];
                if (_tmpSkip1stRewardCollection[_theUser]) {
                    console.log("******* %s collects rewards ******* ", vm.getLabel(_theUser));

                    // Print earnings
                    uint256[] memory _earningsBefore = timedLocker.earned(_theUser);
                    uint256 _rewards0Before = timedLocker.rewards(_theUser, 0);
                    console.log("Earned [before collection]: ", _earningsBefore[0]);
                    console.log("Rewards0 [before collection]: ", _rewards0Before);

                    // Collect rewards
                    hoax(_theUser);
                    uint256[] memory _rtnRewards = timedLocker.getReward(_theUser);
                    _ttlRewardsCollected += _rtnRewards[0];

                    // If the person collected, their earnings should now be 0
                    uint256[] memory _earningsAfter = timedLocker.earned(_theUser);
                    uint256 _rewards0After = timedLocker.rewards(_theUser, 0);
                    console.log("Earned [after collection]: ", _earningsAfter[0]);
                    console.log("Rewards0 [after collection]: ", _rewards0After);
                    assertEq(_earningsAfter[0], 0, "Should have zero earnings after collection");
                } else {
                    console.log("%s does not collect rewards", vm.getLabel(_theUser));
                }
            }

            console.log("Total Rewards collected: ", _ttlRewardsCollected);
        }

        printInfo("======================== END THE WEEK AND ASSESS ========================");

        // Warp ahead 3.5 days
        _warpToAndRollOne(block.timestamp + (3.5 days));

        // See how much everyone earned. The sum should be 7 FXS - _ttlRewardsCollected
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check earnings
                uint256[] memory _earnings = timedLocker.earned(_theUser);
                uint256 _rewards0 = timedLocker.rewards(_theUser, 0);
                console.log("Earned: ", _earnings[0]);
                console.log("Rewards0: ", _rewards0);
                _earnedSum += _earnings[0];

                vm.stopPrank();
            }

            // Analyze findings
            _tmpEarnings = _earnedSum + _ttlRewardsCollected;
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _tmpEarnings);
            assertApproxEqRel(_earnedSum + _ttlRewardsCollected, 7e18, 0.01e18, "Earnings should sum to half of notifyRewardAmount");
        }

        printInfo("======================== WARP AHEAD 3 MONTHS AND OPTIONALLY BULK SYNC EARNED SOME USERS ========================");

        // Warp ahead 3 months
        _warpToAndRollOne(block.timestamp + (3 * (30 days)));

        // Optionally bulk sync the users
        console.log("<<< Optionally bulk syncEarned users >>>");
        {
            address[] memory _usersToSync = new address[](3);
            if (_tmpBulkSyncEarnedUsers[alice]) {
                _usersToSync[0] = alice;
                console.log("<<<    - syncEarned Alice >>>");
            }
            if (_tmpBulkSyncEarnedUsers[bob]) {
                _usersToSync[1] = bob;
                console.log("<<<    - syncEarned Bob >>>");
            }
            if (_tmpBulkSyncEarnedUsers[claire]) {
                _usersToSync[2] = claire;
                console.log("<<<    - syncEarned Claire >>>");
            }
            timedLocker.bulkSyncEarnedUsers(_usersToSync);
        }

        printInfo("======================== WARP AHEAD 3 MONTHS AND CHECK ========================");

        // Warp ahead 3 months
        _warpToAndRollOne(block.timestamp + (3 * (30 days)));

        // See how much everyone earned.
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check earnings
                uint256[] memory _earnings = timedLocker.earned(_theUser);
                uint256 _rewards0 = timedLocker.rewards(_theUser, 0);
                console.log("Earned: ", _earnings[0]);
                console.log("Rewards0: ", _rewards0);
                _earnedSum += _earnings[0];

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _earnedSum + _ttlRewardsCollected);
            assertApproxEqRel(_earnedSum + _ttlRewardsCollected, (7 + (6 * 30)) * 1e18, 0.01e18, "Earnings should have stayed the same or decayed");
        }

        printInfo("======================== TRY TO WITHDRAW (SHOULD FAIL) ========================");

        console.log("<<< Attempting to withdraw (should fail) >>>");
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            console.log("----- %s -----", vm.getLabel(_theUser));

            // Impersonate the user
            vm.startPrank(_theUser);

            // Try (and fail) to withdraw
            vm.expectRevert(TimedLocker.LockerStillActive.selector);
            timedLocker.withdraw(_1stLockAmounts[i], true);

            vm.stopPrank();
        }

        printInfo("======================== WARP AHEAD RIGHT BEFORE UNLOCK ========================");

        // Warp ahead to right before the unlock
        {
            uint256 _timeLeft = timedLocker.periodFinish() - block.timestamp;
            _warpToAndRollOne(block.timestamp + _timeLeft - 1);
        }

        // See how much everyone earned.
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check earnings
                uint256[] memory _earnings = timedLocker.earned(_theUser);
                uint256 _rewards0 = timedLocker.rewards(_theUser, 0);
                console.log("Earned: ", _earnings[0]);
                console.log("Rewards0: ", _rewards0);
                _earnedSum += _earnings[0];

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _earnedSum + _ttlRewardsCollected);
            assertApproxEqRel(_earnedSum + _ttlRewardsCollected, _ttlRewardAmount, 0.01e18, "Total earnings + collections should match total rewards");
        }

        printInfo("======================== WARP AHEAD AFTER UNLOCK ========================");

        // Warp ahead to right after the unlock
        {
            uint256 _timeLeft = timedLocker.periodFinish() - block.timestamp;
            _warpToAndRollOne(block.timestamp + 2);
        }

        // See how much everyone earned.
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check earnings
                uint256[] memory _earnings = timedLocker.earned(_theUser);
                uint256 _rewards0 = timedLocker.rewards(_theUser, 0);
                console.log("Earned: ", _earnings[0]);
                console.log("Rewards0: ", _rewards0);
                _earnedSum += _earnings[0];

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _earnedSum + _ttlRewardsCollected);
            assertApproxEqRel(_earnedSum + _ttlRewardsCollected, _ttlRewardAmount, 0.01e18, "Total earnings + collections should match total rewards");
        }

        printInfo("======================== TRY TO STAKE (SHOULD FAIL) ========================");

        console.log("<<< Attempting to stake (should fail) >>>");
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            console.log("----- %s -----", vm.getLabel(_theUser));

            // Impersonate the user
            vm.startPrank(_theUser);

            // Approve
            fxb.approve(timedLockerAddress, 1e18);

            // Try (and fail) to withdraw
            vm.expectRevert(TimedLocker.LockerHasEnded.selector);
            timedLocker.stake(1e18);

            vm.stopPrank();
        }

        printInfo("======================== SOME PEOPLE WITHDRAW ========================");

        console.log("<<< Some people withdraw, some don't >>>");
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            if (!_tmpLateWithdrawal[_theUser]) {
                // Wording difference for reward collecting upon withdrawal, or not
                string memory _extraWording;
                if (_tmpCollectRewardsOnWithdrawal[_theUser]) {
                    _extraWording = "and collects rewards";
                } else {
                    _extraWording = "and does not collect rewards";
                }

                console.log("******* %s withdraws %s ******* ", vm.getLabel(_theUser), _extraWording);

                // Print earnings
                uint256[] memory _earningsBefore = timedLocker.earned(_theUser);
                uint256 _rewards0Before = timedLocker.rewards(_theUser, 0);
                console.log("Earned [before collection]: ", _earningsBefore[0]);
                console.log("Rewards0 [before collection]: ", _rewards0Before);

                // Withdraw
                hoax(_theUser);
                uint256[] memory _rtnRewards = timedLocker.withdraw(_1stLockAmounts[i], _tmpCollectRewardsOnWithdrawal[_theUser]);
                _ttlRewardsCollected += _rtnRewards[0];

                // If the person collected, their earnings should now be 0
                uint256[] memory _earningsAfter = timedLocker.earned(_theUser);
                uint256 _rewards0After = timedLocker.rewards(_theUser, 0);
                console.log("Earned [after collection]: ", _earningsAfter[0]);
                console.log("Rewards0 [after collection]: ", _rewards0After);
                if (_tmpCollectRewardsOnWithdrawal[_theUser]) {
                    assertEq(_earningsAfter[0], 0, "Should have zero earnings after collection");
                    assertEq(_rewards0After, 0, "Should have zero rewards after collection");
                }
            } else {
                console.log("%s does not withdraw yet", vm.getLabel(_theUser));
            }
        }

        printInfo("======================== WARP AHEAD ONE MONTH AND DO CHECKS ========================");

        // Warp ahead one month
        {
            _warpToAndRollOne(block.timestamp + (30 * DAY));
        }

        // See how much everyone earned.
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check earnings
                uint256[] memory _earnings = timedLocker.earned(_theUser);
                uint256 _rewards0 = timedLocker.rewards(_theUser, 0);
                console.log("Earned: ", _earnings[0]);
                console.log("Rewards0: ", _rewards0);
                _earnedSum += _earnings[0];

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _earnedSum + _ttlRewardsCollected);
            assertApproxEqRel(_earnedSum + _ttlRewardsCollected, _ttlRewardAmount, 0.01e18, "Total earnings + collections should match total rewards");
        }

        printInfo("======================== REMAINING PEOPLE WITHDRAW AND COLLECT ========================");

        console.log("<<< Remaining people withdraw and collect >>>");
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            if (_tmpLateWithdrawal[_theUser]) {
                console.log("******* %s withdraws and collects ******* ", vm.getLabel(_theUser));

                // Print earnings
                uint256[] memory _earningsBefore = timedLocker.earned(_theUser);
                uint256 _rewards0Before = timedLocker.rewards(_theUser, 0);
                console.log("Earned [before collection]: ", _earningsBefore[0]);
                console.log("Rewards0 [before collection]: ", _rewards0Before);

                // Withdraw
                hoax(_theUser);
                uint256[] memory _rtnRewards = timedLocker.withdraw(_1stLockAmounts[i], _tmpCollectRewardsOnWithdrawal[_theUser]);
                _ttlRewardsCollected += _rtnRewards[0];

                // If the person collected, their earnings should now be 0
                uint256[] memory _earningsAfter = timedLocker.earned(_theUser);
                uint256 _rewards0After = timedLocker.rewards(_theUser, 0);
                console.log("Earned [after collection]: ", _earningsAfter[0]);
                console.log("Rewards0 [after collection]: ", _rewards0After);
                if (_tmpCollectRewardsOnWithdrawal[_theUser]) {
                    assertEq(_earningsAfter[0], 0, "Should have zero earnings after collection");
                    assertEq(_rewards0After, 0, "Should have zero rewards after collection");
                }
            } else {
                console.log("%s does not withdraw yet", vm.getLabel(_theUser));
            }
        }

        printInfo("======================== CHECK FINAL EARNINGS ========================");

        // Warp ahead one month
        {
            _warpToAndRollOne(block.timestamp + (30 * DAY));
        }

        // See how much everyone earned.
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check earnings
                uint256[] memory _earnings = timedLocker.earned(_theUser);
                uint256 _rewards0 = timedLocker.rewards(_theUser, 0);
                console.log("Earned: ", _earnings[0]);
                console.log("Rewards0: ", _rewards0);
                _earnedSum += _earnings[0];

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _earnedSum + _ttlRewardsCollected);
            assertApproxEqRel(_earnedSum + _ttlRewardsCollected, _ttlRewardAmount, 0.01e18, "Total earnings + collections should match total rewards");
        }
    }
}
