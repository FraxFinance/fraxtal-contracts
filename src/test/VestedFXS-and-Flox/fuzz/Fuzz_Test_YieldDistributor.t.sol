// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "frax-std/FraxTest.sol";
import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { YieldDistributor } from "src/contracts/VestedFXS-and-Flox/VestedFXS/YieldDistributor.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";

contract Fuzz_Test_YieldDistributor is BaseTestVeFXS {
    // Avoid stack-too-deep
    // =============================
    address[3] _userAddrs;

    mapping(address => uint128) public _1stLockEndTs;
    mapping(address => mapping(uint256 => uint256)) public _multiLockAmounts; // User -> Lock Idx -> Amount locked
    mapping(address => mapping(uint256 => uint256)) public _multiLockTimes; // User -> Lock Idx -> Length of lock
    mapping(address => mapping(uint256 => uint128)) public _multiLockEndTs; // User -> Lock Idx -> Ending TS

    // Lock related
    uint256 _newLockIdTmp;
    mapping(address => uint256[]) public _userCreateLockIds;

    // Earnings / yield
    uint256 _tmpEarnings;
    uint256 _yieldCollected;

    function setUp() public {
        defaultSetup();

        // Mint FXS to this address and the test users
        token.mint(address(this), 10_000e18);
        token.mint(alice, 1000e18);
        token.mint(bob, 1000e18);
        token.mint(claire, 1000e18);

        // Misc test setup
        _userAddrs = [alice, bob, claire];
    }

    function printInfo(string memory _printTitle) public {
        // Print the title
        console.log(_printTitle);

        // Check YD status
        printYDStatus();

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

    function printYDStatus() public {
        console.log("---------- YD ----------");
        console.log("YD: fractionParticipating", yieldDistributor.fractionParticipating());
        console.log("YD: ttlCombinedVeFXSTotalSupply", veFXSAggregator.ttlCombinedVeFXSTotalSupply());
        console.log("YD: lastTimeYieldApplicable", yieldDistributor.lastTimeYieldApplicable());
        console.log("YD: yieldPerVeFXS", yieldDistributor.yieldPerVeFXS());
        console.log("YD: getYieldForDuration", yieldDistributor.getYieldForDuration());
    }

    function testFuzz_SimpleOneLockEach(uint256[3] memory _1stLockAmounts, uint256[3] memory _1stLockTimes, uint256[3] memory _warpTimes, bool[10] memory _miscBools) public {
        printInfo("======================== BOUND FUZZ INPUTS ========================");
        // _1stLockAmounts
        for (uint256 i = 0; i < _1stLockAmounts.length; i++) {
            _1stLockAmounts[i] = bound(_1stLockAmounts[i], 1000 gwei, 50e18);
        }

        // _1stLockTimes
        for (uint256 i = 0; i < _1stLockTimes.length; i++) {
            // Bound to at least 2 week lock
            _1stLockTimes[i] = bound(_1stLockTimes[i], 1 + (14 * DAY), 4 * 365 * DAY);

            // Truncate to the nearest week
            _1stLockEndTs[_userAddrs[i]] = uint128(block.timestamp) + uint128((uint256(_1stLockTimes[i]) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));
        }

        // _warpTimes
        for (uint256 i = 0; i < _warpTimes.length; i++) {
            _warpTimes[i] = bound(_warpTimes[i], 0, 10 * 365 * DAY);
        }

        printInfo("======================== PRINT FUZZ VARIABLES ========================");

        // Alice
        console.log("------------------------ ALICE ------------------------");
        {
            // Amounts
            console.log("_1stLockAmounts: ", _1stLockAmounts[0]);

            // Times
            console.log("_1stLockTimes: ", _1stLockTimes[0]);
            console.log("_1stLockEndTs: ", _1stLockEndTs[alice]);
        }

        // Bob
        console.log("------------------------ BOB ------------------------");
        {
            // Amounts
            console.log("_1stLockAmounts: ", _1stLockAmounts[1]);

            // Times
            console.log("_1stLockTimes: ", _1stLockTimes[1]);
            console.log("_1stLockEndTs: ", _1stLockEndTs[bob]);
        }

        // Claire
        console.log("------------------------ CLAIRE ------------------------");
        {
            // Amounts
            console.log("_1stLockAmounts: ", _1stLockAmounts[2]);

            // Times
            console.log("_1stLockTimes: ", _1stLockTimes[2]);
            console.log("_1stLockEndTs: ", _1stLockEndTs[claire]);
        }
        console.log("------------------------");

        printInfo("======================== NOTIFY REWARD ========================");
        console.log("<<< Put rewards in the YD >>>");

        // Notify rewards and checkpoint
        token.approve(address(yieldDistributor), 10e18);
        yieldDistributor.notifyRewardAmount(10e18);

        printInfo("======================== CREATE LOCKS ========================");

        // Check YD status
        printYDStatus();

        // Create veFXS Locks and checkpoint on the YD
        console.log("<<< Creating initial veFXS locks and checkpointing on the YD >>>");
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Impersonate the user
            vm.startPrank(_theUser);

            // Approve and lock
            token.approve(address(vestedFXS), _1stLockAmounts[i]);
            (, _newLockIdTmp) = vestedFXS.createLock(_theUser, _1stLockAmounts[i], _1stLockEndTs[_theUser]); // #0
            _userCreateLockIds[_theUser].push(_newLockIdTmp);

            // Checkpoint on the YD
            yieldDistributor.checkpoint();

            vm.stopPrank();
        }

        printInfo("======================== WARPING 3.5 DAYS AND CHECKING EARNINGS ========================");

        // Warp ahead 3.5 days
        _warpToAndRollOne(block.timestamp + (3.5 days));

        // See how much everyone earned. The sum should be 5 FXS, half of the initial notifyRewardAmount
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check eligible veFXS
                (uint256 _eligVeFXS,) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
                console.log("eligibleCurrentVeFXS: ", _eligVeFXS);

                // Check earnings
                uint256 _earnedYield = yieldDistributor.earned(_theUser);
                console.log("Earned: ", _earnedYield);
                console.log("Yield: ", yieldDistributor.yields(_theUser));
                _earnedSum += _earnedYield;

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            assertApproxEqRel(_earnedSum, 5e18, 0.01e18, "Earnings should sum to half of notifyRewardAmount");
        }

        printInfo("======================== SOME PEOPLE COLLECT ========================");

        // Various people collect, or don't
        {
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];
                if (_miscBools[i]) {
                    console.log("%s collects yield", vm.getLabel(_theUser));

                    // Collect yield
                    hoax(_theUser);
                    _yieldCollected += yieldDistributor.getYield();
                } else {
                    console.log("%s does not collect yield", vm.getLabel(_theUser));
                }
            }

            console.log("Total Yield collected: ", _yieldCollected);
        }

        printInfo("======================== END THE WEEK AND ASSESS ========================");

        // Warp ahead 3.5 days
        _warpToAndRollOne(block.timestamp + (3.5 days));

        // See how much everyone earned. The sum should be 10 FXS - _yieldCollected
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check eligible veFXS
                (uint256 _eligVeFXS,) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
                console.log("eligibleCurrentVeFXS: ", _eligVeFXS);

                // Check earnings
                uint256 _earnedYield = yieldDistributor.earned(_theUser);
                console.log("Earned: ", _earnedYield);
                console.log("Yield: ", yieldDistributor.yields(_theUser));
                _earnedSum += _earnedYield;

                vm.stopPrank();
            }

            // Analyze findings
            _tmpEarnings = _earnedSum + _yieldCollected;
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _tmpEarnings);
            assertApproxEqRel(_earnedSum + _yieldCollected, 10e18, 0.01e18, "Earnings should sum to half of notifyRewardAmount");
        }

        printInfo("======================== WARP AHEAD 6 MONTHS AND CHECK (NO NEW REWARDS) ========================");

        // Warp ahead 6 months
        _warpToAndRollOne(block.timestamp + (6 * (30 days)));

        // See how much everyone earned. It should start decaying unless they have active veFXS
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check eligible veFXS
                (uint256 _eligVeFXS,) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
                console.log("eligibleCurrentVeFXS: ", _eligVeFXS);

                // Check earnings
                uint256 _earnedYield = yieldDistributor.earned(_theUser);
                console.log("Earned: ", _earnedYield);
                console.log("Yield: ", yieldDistributor.yields(_theUser));
                _earnedSum += _earnedYield;

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _earnedSum + _yieldCollected);
            assertLe(_earnedSum + _yieldCollected, _tmpEarnings, "Earnings should have stayed the same or decayed");
        }
    }

    function testFuzz_ComplexMultiLock(uint256[15] memory _fzMultiLockAmounts, uint256[15] memory _fzMultiLockTimes, uint256[3] memory _warpTimes, bool[10] memory _miscBools) public {
        printInfo("======================== BOUND FUZZ INPUTS ========================");
        // _fzMultiLockAmounts
        for (uint256 i = 0; i < _fzMultiLockAmounts.length; i++) {
            _fzMultiLockAmounts[i] = bound(_fzMultiLockAmounts[i], 1000 gwei, 100e18);
        }

        // _fzMultiLockTimes
        for (uint256 i = 0; i < _fzMultiLockTimes.length; i++) {
            // Bound to at least 2 week lock
            _fzMultiLockTimes[i] = bound(_fzMultiLockTimes[i], 1 + (14 * DAY), 4 * 365 * DAY);
        }

        // _warpTimes
        for (uint256 i = 0; i < _warpTimes.length; i++) {
            _warpTimes[i] = bound(_warpTimes[i], 0, 10 * 365 * DAY);
        }

        printInfo("======================== PRINT / FILL FUZZ VARIABLES ========================");

        // Alice
        console.log("------------------------ ALICE ------------------------");
        {
            // Locks
            for (uint256 i = 0; i < 5; i++) {
                _multiLockAmounts[alice][i] = _fzMultiLockAmounts[i];
                _multiLockTimes[alice][i] = _fzMultiLockTimes[i];
                // Truncate to the nearest week
                _multiLockEndTs[alice][i] = uint128(block.timestamp) + uint128((uint256(_fzMultiLockTimes[i]) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));

                console.log("Lock #%s amount: %s", i, _multiLockAmounts[alice][i]);
                console.log("Lock #%s length: %s", i, _multiLockTimes[alice][i]);
                console.log("Lock #%s ending ts: %s", i, _multiLockEndTs[alice][i]);
            }
        }

        // Bob
        console.log("------------------------ BOB ------------------------");
        {
            // Locks
            for (uint256 i = 0; i < 5; i++) {
                _multiLockAmounts[bob][i] = _fzMultiLockAmounts[i + 5];
                _multiLockTimes[bob][i] = _fzMultiLockTimes[i + 5];
                // Truncate to the nearest week
                _multiLockEndTs[bob][i] = uint128(block.timestamp) + uint128((uint256(_fzMultiLockTimes[i + 5]) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));

                console.log("Lock #%s amount: %s", i, _multiLockAmounts[bob][i]);
                console.log("Lock #%s length: %s", i, _multiLockTimes[bob][i]);
                console.log("Lock #%s ending ts: %s", i, _multiLockEndTs[bob][i]);
            }
        }

        // Claire
        console.log("------------------------ CLAIRE ------------------------");
        {
            // Locks
            for (uint256 i = 0; i < 5; i++) {
                _multiLockAmounts[claire][i] = _fzMultiLockAmounts[i + 10];
                _multiLockTimes[claire][i] = _fzMultiLockTimes[i + 10];
                // Truncate to the nearest week
                _multiLockEndTs[claire][i] = uint128(block.timestamp) + uint128((uint256(_fzMultiLockTimes[i + 10]) / uint256(uint128(WEEK))) * uint256(uint128(WEEK)));

                console.log("Lock #%s amount: %s", i, _multiLockAmounts[claire][i]);
                console.log("Lock #%s length: %s", i, _multiLockTimes[claire][i]);
                console.log("Lock #%s ending ts: %s", i, _multiLockEndTs[claire][i]);
            }
        }
        console.log("------------------------");

        printInfo("======================== NOTIFY REWARD ========================");
        console.log("<<< Put rewards in the YD >>>");

        // Notify rewards and checkpoint
        token.approve(address(yieldDistributor), 10e18);
        yieldDistributor.notifyRewardAmount(10e18);

        printInfo("======================== CREATE LOCKS ========================");

        // Check YD status
        printYDStatus();

        // Create veFXS Locks and checkpoint on the YD
        console.log("<<< Creating initial veFXS locks and checkpointing on the YD >>>");
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Impersonate the user
            vm.startPrank(_theUser);

            // Create the locks
            for (uint256 i = 0; i < 5; i++) {
                // Approve and lock
                token.approve(address(vestedFXS), _multiLockAmounts[_theUser][i]);
                (, _newLockIdTmp) = vestedFXS.createLock(_theUser, _multiLockAmounts[_theUser][i], _multiLockEndTs[_theUser][i]); // #0
                _userCreateLockIds[_theUser].push(_newLockIdTmp);
            }

            // Checkpoint on the YD
            yieldDistributor.checkpoint();

            vm.stopPrank();
        }

        printInfo("======================== WARPING 3.5 DAYS AND CHECKING EARNINGS ========================");

        // Warp ahead 3.5 days
        _warpToAndRollOne(block.timestamp + (3.5 days));

        // See how much everyone earned. The sum should be 5 FXS, half of the initial notifyRewardAmount
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check eligible veFXS
                (uint256 _eligVeFXS,) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
                console.log("eligibleCurrentVeFXS: ", _eligVeFXS);

                // Check earnings
                uint256 _earnedYield = yieldDistributor.earned(_theUser);
                console.log("Earned: ", _earnedYield);
                console.log("Yield: ", yieldDistributor.yields(_theUser));
                _earnedSum += _earnedYield;

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            assertApproxEqRel(_earnedSum, 5e18, 0.01e18, "Earnings should sum to half of notifyRewardAmount");
        }

        printInfo("======================== SOME PEOPLE COLLECT ========================");

        // Various people collect, or don't
        {
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];
                if (_miscBools[i]) {
                    console.log("%s collects yield", vm.getLabel(_theUser));

                    // Collect yield
                    hoax(_theUser);
                    _yieldCollected += yieldDistributor.getYield();
                } else {
                    console.log("%s does not collect yield", vm.getLabel(_theUser));
                }
            }

            console.log("Total Yield collected: ", _yieldCollected);
        }

        printInfo("======================== END THE WEEK AND ASSESS ========================");

        // Warp ahead 3.5 days
        _warpToAndRollOne(block.timestamp + (3.5 days));

        // See how much everyone earned. The sum should be 10 FXS - _yieldCollected
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check eligible veFXS
                (uint256 _eligVeFXS,) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
                console.log("eligibleCurrentVeFXS: ", _eligVeFXS);

                // Check earnings
                uint256 _earnedYield = yieldDistributor.earned(_theUser);
                console.log("Earned: ", _earnedYield);
                console.log("Yield: ", yieldDistributor.yields(_theUser));
                _earnedSum += _earnedYield;

                vm.stopPrank();
            }

            // Analyze findings
            _tmpEarnings = _earnedSum + _yieldCollected;
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _tmpEarnings);
            assertApproxEqRel(_earnedSum + _yieldCollected, 10e18, 0.01e18, "Earnings should sum to half of notifyRewardAmount");
        }

        printInfo("======================== WARP AHEAD 6 MONTHS AND CHECK (NO NEW REWARDS) ========================");

        // Warp ahead 6 months
        _warpToAndRollOne(block.timestamp + (6 * (30 days)));

        // See how much everyone earned. It should start decaying unless they have active veFXS
        console.log("<<< Check earnings >>>");
        {
            uint256 _earnedSum;
            for (uint256 i = 0; i < _userAddrs.length; i++) {
                // Get the user
                address _theUser = _userAddrs[i];

                console.log("----- %s -----", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Check eligible veFXS
                (uint256 _eligVeFXS,) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
                console.log("eligibleCurrentVeFXS: ", _eligVeFXS);

                // Check earnings
                uint256 _earnedYield = yieldDistributor.earned(_theUser);
                console.log("Earned: ", _earnedYield);
                console.log("Yield: ", yieldDistributor.yields(_theUser));
                _earnedSum += _earnedYield;

                vm.stopPrank();
            }

            // Analyze findings
            console.log("Total Earnings: ", _earnedSum);
            console.log("Total Earnings with previous collected earnings: ", _earnedSum + _yieldCollected);
            assertLe(_earnedSum + _yieldCollected, _tmpEarnings, "Earnings should have stayed the same or decayed");
        }
    }
}
