// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import { console } from "frax-std/FraxTest.sol";
import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";

/* solhint-disable */
contract Fuzz_MegaTest_VeFXS is BaseTestVeFXS {
    using stdStorage for StdStorage;

    // For test tracking
    uint256 startBlockNumber;
    uint256 startTimestamp;

    // Temporary variables to help with stack-too-deep
    address[3] public _userAddrs;
    uint256 _expectedVeFXS;
    uint256 _actualVeFXS;
    uint256 _newLockIdTmp;
    uint128 _earliestLockEnd;
    uint128 _latestLockEnd;

    // DetailedUserLockInfo _userLockInfo;
    LockedBalance[] _allLocks;
    LockedBalance[] _activeLocks;
    LockedBalance[] _expiredLocks;

    // Used for testing. The n-th id pertains to the n-th createLock, regardless of its true index
    mapping(address => uint256[]) public _userCreateLockIds;
    mapping(address => bool) public _userCreate1stLockSucceeded;
    mapping(address => bool) public _userCreate2ndLockSucceeded;
    mapping(address => bool) public _userWithdraw1stLockSucceeded;
    uint256[] _aliceCreateLockIds;
    uint256[] _bobCreateLockIds;
    uint256[] _claireCreateLockIds;
    uint256 _createLock1IdTmp;
    uint256 _createLock2IdTmp;

    // For fuzzing (bools)
    uint256 _numFuzzBoolMappings = 7;
    mapping(address => bool) public _doStep1Create1stLock;
    mapping(address => bool) public _doStep2Create2ndLock;
    mapping(address => bool) public _doStep2Withdraw1stLock;
    mapping(address => bool) public _doStep2IncreaseAmount;
    mapping(address => bool) public _doStep2IncreaseUnlockTime;
    mapping(address => bool) public _doStep3Withdraw1stLock;
    mapping(address => bool) public _doStep3Withdraw2ndLock;
    bool[4] public _doWarpCheckpointing; // Whether to checkpoint inside of warps or not
    bool public _doEmergencyUnlock;
    bool public _doPause;
    bool public _doUnpause;

    // For fuzzing (lock amounts)
    uint256 _numFuzzLockAmountMappings = 3;
    mapping(address => uint256) public _initialLockAmount;
    mapping(address => uint256) public _2ndLockAmount;
    mapping(address => uint256) public _increaseAmountAmount;

    // For fuzzing (lock times)
    uint256 _numFuzzLockTimeMappings = 3;
    mapping(address => uint256) public _initialLockTime;
    mapping(address => uint256) public _2ndLockTime;
    mapping(address => uint256) public _increaseUnlockTimeTime;

    function setUp() public {
        defaultSetup();

        // Mint FXS to the test users
        token.mint(alice, 10_000e18);
        token.mint(bob, 10_000e18);
        token.mint(claire, 10_000e18);
        token.mint(dave, 1e18);

        // Set some state variables for tracking
        _userAddrs = [alice, bob, claire];
        startBlockNumber = block.number;
        startTimestamp = block.timestamp;
    }

    function printInfo(string memory _printTitle) public {
        // Print the title
        console.log(_printTitle);

        // Alice
        _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(alice);
        _actualVeFXS = vestedFXS.balanceOf(alice);
        console.log("Alice expected veFXS balance:", _expectedVeFXS);
        console.log("Alice actual veFXS balance:", _actualVeFXS);

        // Bob
        _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(bob);
        _actualVeFXS = vestedFXS.balanceOf(bob);
        console.log("Bob expected veFXS balance:", _expectedVeFXS);
        console.log("Bob actual veFXS balance:", _actualVeFXS);

        // Claire
        _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(claire);
        _actualVeFXS = vestedFXS.balanceOf(claire);
        console.log("Claire expected veFXS balance:", _expectedVeFXS);
        console.log("Claire actual veFXS balance:", _actualVeFXS);

        // Dave
        _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(dave);
        _actualVeFXS = vestedFXS.balanceOf(dave);
        console.log("Dave expected veFXS balance:", _expectedVeFXS);
        console.log("Dave actual veFXS balance:", _actualVeFXS);
    }

    function test_E2E_Main() public {
        printInfo("======================== BEGINNING ========================");
        console.log("<<< Creating initial locks >>>");

        // Warp to right before the start of the next epoch
        _warpToAndRollOne((((block.timestamp / 604_800)) * 604_800) - 1);

        // Alice locks 100 tokens for 4/3 years to get 2x
        // ======================================================
        // Approve
        hoax(alice);
        token.approve(address(vestedFXS), 100e18);

        // Truncate to nearest week
        uint128 unlockTimestamp = ((uint128(block.timestamp) + LOCK_SECONDS_2X) / uint128(WEEK)) * uint128(WEEK);

        // Create the lock
        hoax(alice);
        (, _newLockIdTmp) = vestedFXS.createLock(alice, 100e18, unlockTimestamp); // #0
        _aliceCreateLockIds.push(_newLockIdTmp);

        // Print some info and check Alice's balance
        _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(alice);
        _actualVeFXS = vestedFXS.balanceOf(alice);
        console.log("Alice expected veFXS balance:", _expectedVeFXS);
        console.log("Alice actual veFXS balance:", _actualVeFXS);
        assertApproxEqRel(_expectedVeFXS, _actualVeFXS, 0.01e18, "Alice's _expectedVeFXS vs _actualVeFXS");
        assertApproxEqRel(vestedFXS.balanceOf(alice), 200e18, 0.01e18, "Alice's initial veFXS balance");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtBlock(alice, block.number), 200e18, 0.01e18, "Alice's initial veFXS balance (balanceOfAllLocksAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtTime(alice, block.timestamp), 200e18, 0.01e18, "Alice's initial veFXS balance (balanceOfAllLocksAtTime)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtBlock(alice, 0, block.number), 200e18, 0.01e18, "Alice's initial veFXS balance (balanceOfOneLockAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtTime(alice, 0, block.timestamp), 200e18, 0.01e18, "Alice's initial veFXS balance (balanceOfOneLockAtTime)");

        // Bob locks 100 tokens for 8/3 years to get 3x
        // ======================================================
        // Approve
        hoax(bob);
        token.approve(address(vestedFXS), 100e18);

        // Truncate to nearest week
        unlockTimestamp = ((uint128(block.timestamp) + LOCK_SECONDS_3X) / uint128(WEEK)) * uint128(WEEK);

        // Create the lock
        hoax(bob);
        (, _newLockIdTmp) = vestedFXS.createLock(bob, 100e18, unlockTimestamp); // #0
        _bobCreateLockIds.push(_newLockIdTmp);

        // Print some info and check Bob's balance
        _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(bob);
        _actualVeFXS = vestedFXS.balanceOf(bob);
        console.log("Bob expected veFXS balance:", _expectedVeFXS);
        console.log("Bob actual veFXS balance:", _actualVeFXS);
        assertApproxEqRel(_expectedVeFXS, _actualVeFXS, 0.01e18, "Bob's _expectedVeFXS vs _actualVeFXS");
        assertApproxEqRel(vestedFXS.balanceOf(bob), 300e18, 0.01e18, "Bob's initial veFXS");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtBlock(bob, block.number), 300e18, 0.01e18, "Bobs's initial veFXS balance (balanceOfAllLocksAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtTime(bob, block.timestamp), 300e18, 0.01e18, "Bobs's initial veFXS balance (balanceOfAllLocksAtTime)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtBlock(bob, 0, block.number), 300e18, 0.01e18, "Bobs's initial veFXS balance (balanceOfOneLockAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtTime(bob, 0, block.timestamp), 300e18, 0.01e18, "Bobs's initial veFXS balance (balanceOfOneLockAtTime)");

        // Claire locks 100 tokens for 4 years to get 4x
        // ======================================================
        // Approve
        hoax(claire);
        token.approve(address(vestedFXS), 100e18);

        // Truncate to nearest week
        unlockTimestamp = ((uint128(block.timestamp) + LOCK_SECONDS_4X) / uint128(WEEK)) * uint128(WEEK);

        // Create the lock
        hoax(claire);
        (, _newLockIdTmp) = vestedFXS.createLock(claire, 100e18, unlockTimestamp); // #0
        _claireCreateLockIds.push(_newLockIdTmp);

        // Print some info and check Claire's balance
        _expectedVeFXS = vestedFXSUtils.getCrudeExpectedVeFXSUser(claire);
        _actualVeFXS = vestedFXS.balanceOf(claire);
        console.log("Claire expected veFXS balance:", _expectedVeFXS);
        console.log("Claire actual veFXS balance:", _actualVeFXS);
        assertApproxEqRel(_expectedVeFXS, _actualVeFXS, 0.01e18, "Claire's _expectedVeFXS vs _actualVeFXS");
        assertApproxEqRel(vestedFXS.balanceOf(claire), 400e18, 0.01e18, "Claire's initial veFXS balance (balanceOf)");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtBlock(claire, block.number), 400e18, 0.01e18, "Claire's initial veFXS balance (balanceOfAllLocksAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfAllLocksAtTime(claire, block.timestamp), 400e18, 0.01e18, "Claire's initial veFXS balance (balanceOfAllLocksAtTime)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtBlock(claire, 0, block.number), 400e18, 0.01e18, "Claire's initial veFXS balance (balanceOfOneLockAtBlock)");
        assertApproxEqRel(vestedFXS.balanceOfOneLockAtTime(claire, 0, block.timestamp), 400e18, 0.01e18, "Claire's initial veFXS balance (balanceOfOneLockAtTime)");

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER INITIAL LOCKS ========================");
        console.log("<<< Creating new locks, but advancing a 3 days first >>>");
        // Advance three days
        advanceTimeWithCheckpointing(3 * DAY, 1 * DAY, new bytes(0));

        // Alice locks various amounts of tokens for various lengths
        // ======================================================
        // Impersonate Alice
        vm.startPrank(alice);

        // Approve
        token.approve(address(vestedFXS), 100e18);

        // Create Locks
        (, _newLockIdTmp) = vestedFXS.createLock(alice, 50e18, uint128(block.timestamp + (75 days)));
        _aliceCreateLockIds.push(_newLockIdTmp); // #1
        (, _newLockIdTmp) = vestedFXS.createLock(alice, 25e18, uint128(block.timestamp + (180 days)));
        _aliceCreateLockIds.push(_newLockIdTmp); // #2
        (, _newLockIdTmp) = vestedFXS.createLock(alice, 15e18, uint128(block.timestamp + (730 days)));
        _aliceCreateLockIds.push(_newLockIdTmp); // #3
        (, _newLockIdTmp) = vestedFXS.createLock(alice, 10e18, uint128(block.timestamp + (1095 days)));
        _aliceCreateLockIds.push(_newLockIdTmp); // #4

        // Stop impersonation
        vm.stopPrank();

        // Bob locks various amounts of tokens for various lengths
        // ======================================================
        // Impersonate Bob
        vm.startPrank(bob);

        // Approve
        token.approve(address(vestedFXS), 100e18);

        // Create Locks
        (, _newLockIdTmp) = vestedFXS.createLock(bob, 40e18, uint128(block.timestamp + (90 days)));
        _bobCreateLockIds.push(_newLockIdTmp); // #1
        (, _newLockIdTmp) = vestedFXS.createLock(bob, 30e18, uint128(block.timestamp + (250 days)));
        _bobCreateLockIds.push(_newLockIdTmp); // #2
        (, _newLockIdTmp) = vestedFXS.createLock(bob, 20e18, uint128(block.timestamp + (500 days)));
        _bobCreateLockIds.push(_newLockIdTmp); // #3
        (, _newLockIdTmp) = vestedFXS.createLock(bob, 10e18, uint128(block.timestamp + (750 days)));
        _bobCreateLockIds.push(_newLockIdTmp); // #4

        // Stop impersonation
        vm.stopPrank();

        // Claire locks various amounts of tokens for various lengths
        // ======================================================
        // Impersonate Claire
        vm.startPrank(claire);

        // Approve
        token.approve(address(vestedFXS), 100e18);

        // Create Locks
        (, _newLockIdTmp) = vestedFXS.createLock(claire, 70e18, uint128(block.timestamp + (30 days)));
        _claireCreateLockIds.push(_newLockIdTmp); // #1
        (, _newLockIdTmp) = vestedFXS.createLock(claire, 15e18, uint128(block.timestamp + (60 days)));
        _claireCreateLockIds.push(_newLockIdTmp); // #2
        (, _newLockIdTmp) = vestedFXS.createLock(claire, 10e18, uint128(block.timestamp + (85 days)));
        _claireCreateLockIds.push(_newLockIdTmp); // #3
        (, _newLockIdTmp) = vestedFXS.createLock(claire, 5e18, uint128(block.timestamp + (150 days)));
        _claireCreateLockIds.push(_newLockIdTmp); // #4

        // Stop impersonation
        vm.stopPrank();

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER MISC NEW LOCKS ========================");

        // Invariant checks (before time increase)
        // ======================================================
        checkInvariants();

        // Advance 100 days
        console.log("<<< Advancing 100 days, with checkpointing >>>");
        advanceTimeWithCheckpointing(100 * DAY, 3 * DAY, new bytes(0));

        // Invariant checks (after time increase)
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER 100 DAYS IN (WITH CHECKPOINTING) ========================");
        console.log("<<< Misc withdraws, extensions, and increase amounting >>>");

        // Alice does absolutely nothing, even though one of her locks expired
        // ======================================================
        // Do nothing

        // Bob withdraws one of his locks, extends another, increase amounts a third, and leaves the last one alone
        // ======================================================

        // Impersonate Bob
        vm.startPrank(bob);

        // Withdraw the expired lock
        vestedFXS.withdraw(vestedFXS.getLockIndexById(bob, _bobCreateLockIds[1]));

        // Add to another lock
        token.approve(address(vestedFXS), 10e18);
        vestedFXS.increaseAmount(10e18, vestedFXS.getLockIndexById(bob, _bobCreateLockIds[2]));

        // Extend the lock time for the 3rd
        vestedFXS.increaseUnlockTime(uint128(block.timestamp + (510 days)), vestedFXS.getLockIndexById(bob, _bobCreateLockIds[3]));

        // Stop impersonation
        vm.stopPrank();

        // Claire withdraws some of her expired locks and add & extends the 4th
        // ======================================================

        // Impersonate Claire
        vm.startPrank(claire);

        // Withdraw some expired locks
        vestedFXS.withdraw(vestedFXS.getLockIndexById(claire, _claireCreateLockIds[1]));
        vestedFXS.withdraw(vestedFXS.getLockIndexById(claire, _claireCreateLockIds[2]));
        vestedFXS.withdraw(vestedFXS.getLockIndexById(claire, _claireCreateLockIds[3]));

        // Both add to and extend the 4th
        token.approve(address(vestedFXS), 50e18);
        vestedFXS.increaseAmount(50e18, vestedFXS.getLockIndexById(claire, _claireCreateLockIds[4]));
        vestedFXS.increaseUnlockTime(uint128(block.timestamp + (175 days)), vestedFXS.getLockIndexById(claire, _claireCreateLockIds[4]));

        // Stop impersonation
        vm.stopPrank();

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER MISC ACTIVITIES ========================");
        // Advance 30 days
        // Skip checkpointing here to see if something messes up

        console.log("<<< Advancing 30 days, without checkpointing >>>");
        mineBlocksBySecond(30 * DAY);

        // Invariant checks (after time increase)
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER ADVANCING 30 DAYS (WITHOUT CHECKPOINTING) ========================");
        console.log("<<< Creating one new lock each >>>");

        // Alice creates a new lock
        // ======================================================
        // Impersonate Alice
        vm.startPrank(alice);

        // Approve
        token.approve(address(vestedFXS), 25e18);

        // Create Lock
        (, _newLockIdTmp) = vestedFXS.createLock(alice, 25e18, uint128(block.timestamp + (175 days))); // #5
        _aliceCreateLockIds.push(_newLockIdTmp);

        // Stop impersonation
        vm.stopPrank();

        // Bob creates a new lock
        // ======================================================
        // Impersonate Bob
        vm.startPrank(bob);

        // Approve
        token.approve(address(vestedFXS), 125e18);

        // Create Lock
        (, _newLockIdTmp) = vestedFXS.createLock(bob, 125e18, uint128(block.timestamp + (275 days))); // #5
        _bobCreateLockIds.push(_newLockIdTmp);

        // Stop impersonation
        vm.stopPrank();

        // Claire creates a new lock
        // ======================================================
        // Impersonate Claire
        vm.startPrank(claire);

        // Approve
        token.approve(address(vestedFXS), 250e18);

        // Create Locks
        (, _newLockIdTmp) = vestedFXS.createLock(claire, 15e18, uint128(block.timestamp + (375 days))); // #5
        _claireCreateLockIds.push(_newLockIdTmp);

        // Stop impersonation
        vm.stopPrank();

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER CREATING NEW LOCKS ========================");

        // Advance 300 days
        console.log("<<< Advancing 300 days, with checkpointing >>>");
        advanceTimeWithCheckpointing(300 * DAY, 7 * DAY, new bytes(0));

        // Invariant checks (after time increase)
        // ======================================================
        checkInvariants();

        printInfo("======================== ADVANCED 300 DAYS (WITH CHECKPOINTING) ========================");
        console.log("<<< Withdrawing expired positions (1st time) >>>");

        // Alice withdraws her expired positions
        // ======================================================
        // Impersonate Alice
        vm.startPrank(alice);

        // Fetch Alice's expired positions
        DetailedUserLockInfo memory _userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(alice);

        // Loop through the expired positions and withdraw
        for (uint256 i; i < _userLockInfo.expiredLocks.length; i++) {
            // Get the expired lock
            LockedBalanceExtended memory _thisLock = _userLockInfo.expiredLocks[i];

            // Withdraw the lock
            // The index changes after each withdraw, so you have to call veFXS to check
            vestedFXS.withdraw(vestedFXS.getLockIndexById(alice, _thisLock.id));
        }

        // Stop impersonation
        vm.stopPrank();

        // Bob withdraws his expired positions
        // ======================================================
        // Impersonate Bob
        vm.startPrank(bob);

        // Fetch Bob's expired positions
        _userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);

        // Loop through the expired positions and withdraw
        for (uint256 i; i < _userLockInfo.expiredLocks.length; i++) {
            // Get the expired lock
            LockedBalanceExtended memory _thisLock = _userLockInfo.expiredLocks[i];

            // Withdraw the lock
            // The index changes after each withdraw, so you have to call veFXS to check
            vestedFXS.withdraw(vestedFXS.getLockIndexById(bob, _thisLock.id));
        }

        // Stop impersonation
        vm.stopPrank();

        // Claire withdraws her expired positions
        // ======================================================
        // Impersonate Claire
        vm.startPrank(claire);

        // Fetch Claire's expired positions
        _userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(claire);

        // Loop through the expired positions and withdraw
        for (uint256 i; i < _userLockInfo.expiredLocks.length; i++) {
            // Get the expired lock
            LockedBalanceExtended memory _thisLock = _userLockInfo.expiredLocks[i];

            // Withdraw the lock
            // The index changes after each withdraw, so you have to call veFXS to check
            vestedFXS.withdraw(vestedFXS.getLockIndexById(claire, _thisLock.id));
        }

        // Stop impersonation
        vm.stopPrank();

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER WITHDRAWING EXPIRED POSITIONS ========================");

        // Advance 1500 days
        console.log("<<< Advancing 1500 days, with checkpointing >>>");
        advanceTimeWithCheckpointing(1500 * DAY, 30 * DAY, new bytes(0));

        // Invariant checks (after time increase)
        // ======================================================
        checkInvariants();

        printInfo("======================== ADVANCED 1500 DAYS (WITH CHECKPOINTING) ========================");
        console.log("<<< Withdrawing expired positions (2nd time) >>>");

        // Alice withdraws her expired positions
        // ======================================================
        // Impersonate Alice
        vm.startPrank(alice);

        // Fetch Alice's expired positions
        _userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(alice);

        // Loop through the expired positions and withdraw
        for (uint256 i; i < _userLockInfo.expiredLocks.length; i++) {
            // Get the expired lock
            LockedBalanceExtended memory _thisLock = _userLockInfo.expiredLocks[i];

            // Withdraw the lock
            // The index changes after each withdraw, so you have to call veFXS to check
            vestedFXS.withdraw(vestedFXS.getLockIndexById(alice, _thisLock.id));
        }

        // Stop impersonation
        vm.stopPrank();

        // Bob withdraws his expired positions
        // ======================================================
        // Impersonate Bob
        vm.startPrank(bob);

        // Fetch Bob's expired positions
        _userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);

        // Loop through the expired positions and withdraw
        for (uint256 i; i < _userLockInfo.expiredLocks.length; i++) {
            // Get the expired lock
            LockedBalanceExtended memory _thisLock = _userLockInfo.expiredLocks[i];

            // Withdraw the lock
            // The index changes after each withdraw, so you have to call veFXS to check
            vestedFXS.withdraw(vestedFXS.getLockIndexById(bob, _thisLock.id));
        }

        // Stop impersonation
        vm.stopPrank();

        // Claire withdraws her expired positions
        // ======================================================
        // Impersonate Claire
        vm.startPrank(claire);

        // Fetch Claire's expired positions
        _userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(claire);

        // Loop through the expired positions and withdraw
        for (uint256 i; i < _userLockInfo.expiredLocks.length; i++) {
            // Get the expired lock
            LockedBalanceExtended memory _thisLock = _userLockInfo.expiredLocks[i];

            // Withdraw the lock
            // The index changes after each withdraw, so you have to call veFXS to check
            vestedFXS.withdraw(vestedFXS.getLockIndexById(claire, _thisLock.id));
        }

        // Stop impersonation
        vm.stopPrank();

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== FINAL RESULTS (SHOULD BE 0) ========================");
    }

    function testFuzz_E2E(
        bool[25] memory _miscFzBools, // Will be used to determine certain action paths
        uint256[12] memory _miscLockAmounts, // Used for createLocks and increaseAmount
        uint256[12] memory _miscLockTimes, // Used for createLocks and increaseUnlockTime
        uint256[4] memory _warpTimes // Variable length of time between steps
    ) public {
        // Setup the fuzz variables
        // ====================================

        // ======================== BOUND FUZZ INPUTS ========================
        // _miscLockAmounts
        for (uint256 i = 0; i < _miscLockAmounts.length; i++) {
            _miscLockAmounts[i] = bound(_miscLockAmounts[i], 1000 gwei, 2000e18);
        }

        // _miscLockTimes
        for (uint256 i = 0; i < _miscLockTimes.length; i++) {
            _miscLockTimes[i] = bound(_miscLockTimes[i], 1, 4 * 365 * DAY);
        }

        // Less frequent actions
        if ((_warpTimes[0] % 10) == 1) _doEmergencyUnlock = true;
        if ((_warpTimes[1] % 10) == 1) _doPause = true;
        if (_doPause && (_warpTimes[2] % 2) == 1) _doUnpause = true;

        // NOTE to devs: Withdrawals after emergency unlocking can permanently disrupt veFXS balances, so disregard invariant checks when they are active
        // _doEmergencyUnlock = false; // Overriding here
        console.log("_doEmergencyUnlock: ", _doEmergencyUnlock);
        console.log("_doPause: ", _doPause);
        console.log("_doUnpause: ", _doUnpause);

        // _warpTimes
        console.log("------------------------ WARP TIMES ------------------------");
        for (uint256 i = 0; i < _warpTimes.length; i++) {
            _warpTimes[i] = bound(_warpTimes[i], 0, 4 * 365 * DAY);
            console.log("_warpTimes[%d]: %d", i, _warpTimes[i]);
        }

        // _doWarpCheckpointing
        for (uint256 i = 0; i < _doWarpCheckpointing.length; i++) {
            _doWarpCheckpointing[i] = _miscFzBools[(3 * _numFuzzBoolMappings) + i];
        }

        // ============= FILL STACK-REDUCING STATE VARIABLES ============

        // Fill in fuzz variables
        // =====================

        // Alice
        console.log("------------------------ ALICE ------------------------");
        {
            // Bools
            _doStep1Create1stLock[alice] = _miscFzBools[0];
            _doStep2Create2ndLock[alice] = _miscFzBools[1];
            _doStep2Withdraw1stLock[alice] = _miscFzBools[2];
            _doStep2IncreaseAmount[alice] = _miscFzBools[3];
            _doStep2IncreaseUnlockTime[alice] = _miscFzBools[4];
            _doStep3Withdraw1stLock[alice] = _miscFzBools[5];
            _doStep3Withdraw2ndLock[alice] = _miscFzBools[6];
            console.log("_doStep1Create1stLock: ", _doStep1Create1stLock[alice]);
            console.log("_doStep2Create2ndLock: ", _doStep2Create2ndLock[alice]);
            console.log("_doStep2Withdraw1stLock: ", _doStep2Withdraw1stLock[alice]);
            console.log("_doStep2IncreaseAmount: ", _doStep2IncreaseAmount[alice]);
            console.log("_doStep2IncreaseUnlockTime: ", _doStep2IncreaseUnlockTime[alice]);
            console.log("_doStep3Withdraw1stLock: ", _doStep3Withdraw1stLock[alice]);
            console.log("_doStep3Withdraw2ndLock: ", _doStep3Withdraw2ndLock[alice]);

            // Amounts
            _initialLockAmount[alice] = _miscLockAmounts[0];
            _2ndLockAmount[alice] = _miscLockAmounts[1];
            _increaseAmountAmount[alice] = _miscLockAmounts[2];
            console.log("_initialLockAmount: ", _initialLockAmount[alice]);
            console.log("_2ndLockAmount: ", _2ndLockAmount[alice]);
            console.log("_increaseAmountAmount: ", _increaseAmountAmount[alice]);

            // Times
            _initialLockTime[alice] = _miscLockTimes[0];
            _2ndLockTime[alice] = _miscLockTimes[1];
            _increaseUnlockTimeTime[alice] = _miscLockTimes[2];
            console.log("_initialLockTime: ", _initialLockTime[alice]);
            console.log("_2ndLockTime: ", _2ndLockTime[alice]);
            console.log("_increaseUnlockTimeTime: ", _increaseUnlockTimeTime[alice]);
        }

        // Bob
        console.log("------------------------ BOB ------------------------");
        {
            // Bools
            _doStep1Create1stLock[bob] = _miscFzBools[_numFuzzBoolMappings + 0];
            _doStep2Create2ndLock[bob] = _miscFzBools[_numFuzzBoolMappings + 1];
            _doStep2Withdraw1stLock[bob] = _miscFzBools[_numFuzzBoolMappings + 2];
            _doStep2IncreaseAmount[bob] = _miscFzBools[_numFuzzBoolMappings + 3];
            _doStep2IncreaseUnlockTime[bob] = _miscFzBools[_numFuzzBoolMappings + 4];
            _doStep3Withdraw1stLock[bob] = _miscFzBools[_numFuzzBoolMappings + 5];
            _doStep3Withdraw2ndLock[bob] = _miscFzBools[_numFuzzBoolMappings + 6];
            console.log("_doStep1Create1stLock: ", _doStep1Create1stLock[bob]);
            console.log("_doStep2Create2ndLock: ", _doStep2Create2ndLock[bob]);
            console.log("_doStep2Withdraw1stLock: ", _doStep2Withdraw1stLock[bob]);
            console.log("_doStep2IncreaseAmount: ", _doStep2IncreaseAmount[bob]);
            console.log("_doStep2IncreaseUnlockTime: ", _doStep2IncreaseUnlockTime[bob]);
            console.log("_doStep3Withdraw1stLock: ", _doStep3Withdraw1stLock[bob]);
            console.log("_doStep3Withdraw2ndLock: ", _doStep3Withdraw2ndLock[bob]);

            // Amounts
            _initialLockAmount[bob] = _miscLockAmounts[_numFuzzLockAmountMappings + 0];
            _2ndLockAmount[bob] = _miscLockAmounts[_numFuzzLockAmountMappings + 1];
            _increaseAmountAmount[bob] = _miscLockAmounts[_numFuzzLockAmountMappings + 2];
            console.log("_initialLockAmount: ", _initialLockAmount[bob]);
            console.log("_2ndLockAmount: ", _2ndLockAmount[bob]);
            console.log("_increaseAmountAmount: ", _increaseAmountAmount[bob]);

            // Times
            _initialLockTime[bob] = _miscLockTimes[_numFuzzLockTimeMappings + 0];
            _2ndLockTime[bob] = _miscLockTimes[_numFuzzLockTimeMappings + 1];
            _increaseUnlockTimeTime[bob] = _miscLockTimes[_numFuzzLockTimeMappings + 2];
            console.log("_initialLockTime: ", _initialLockTime[bob]);
            console.log("_2ndLockTime: ", _2ndLockTime[bob]);
            console.log("_increaseUnlockTimeTime: ", _increaseUnlockTimeTime[bob]);
        }

        // Claire
        console.log("------------------------ CLAIRE ------------------------");
        {
            // Bools
            _doStep1Create1stLock[claire] = _miscFzBools[(2 * _numFuzzBoolMappings) + 0];
            _doStep2Create2ndLock[claire] = _miscFzBools[(2 * _numFuzzBoolMappings) + 1];
            _doStep2Withdraw1stLock[claire] = _miscFzBools[(2 * _numFuzzBoolMappings) + 2];
            _doStep2IncreaseAmount[claire] = _miscFzBools[(2 * _numFuzzBoolMappings) + 3];
            _doStep2IncreaseUnlockTime[claire] = _miscFzBools[(2 * _numFuzzBoolMappings) + 4];
            _doStep3Withdraw1stLock[claire] = _miscFzBools[(2 * _numFuzzBoolMappings) + 5];
            _doStep3Withdraw2ndLock[claire] = _miscFzBools[(2 * _numFuzzBoolMappings) + 6];
            console.log("_doStep1Create1stLock: ", _doStep1Create1stLock[claire]);
            console.log("_doStep2Create2ndLock: ", _doStep2Create2ndLock[claire]);
            console.log("_doStep2Withdraw1stLock: ", _doStep2Withdraw1stLock[claire]);
            console.log("_doStep2IncreaseAmount: ", _doStep2IncreaseAmount[claire]);
            console.log("_doStep2IncreaseUnlockTime: ", _doStep2IncreaseUnlockTime[claire]);
            console.log("_doStep3Withdraw1stLock: ", _doStep3Withdraw1stLock[claire]);
            console.log("_doStep3Withdraw2ndLock: ", _doStep3Withdraw2ndLock[claire]);

            // Amounts
            _initialLockAmount[claire] = _miscLockAmounts[(2 * _numFuzzLockAmountMappings) + 0];
            _2ndLockAmount[claire] = _miscLockAmounts[(2 * _numFuzzLockAmountMappings) + 1];
            _increaseAmountAmount[claire] = _miscLockAmounts[(2 * _numFuzzLockAmountMappings) + 2];
            console.log("_initialLockAmount: ", _initialLockAmount[claire]);
            console.log("_2ndLockAmount: ", _2ndLockAmount[claire]);
            console.log("_increaseAmountAmount: ", _increaseAmountAmount[claire]);

            // Times
            _initialLockTime[claire] = _miscLockTimes[(2 * _numFuzzLockTimeMappings) + 0];
            _2ndLockTime[claire] = _miscLockTimes[(2 * _numFuzzLockTimeMappings) + 1];
            _increaseUnlockTimeTime[claire] = _miscLockTimes[(2 * _numFuzzLockTimeMappings) + 2];
            console.log("_initialLockTime: ", _initialLockTime[claire]);
            console.log("_2ndLockTime: ", _2ndLockTime[claire]);
            console.log("_increaseUnlockTimeTime: ", _increaseUnlockTimeTime[claire]);
        }
        console.log("------------------------");

        // Warp to right before the start of the next epoch
        _warpToAndRollOne((((block.timestamp / 604_800)) * 604_800) - 1);

        // Checkpoint
        vestedFXS.checkpoint();

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== BEGINNING ========================");

        // TODOS
        // 1) Check Max number of locks
        // 2) depositFor

        // Dave locks 1 token for 1 week with no plans to withdraw it, to make sure the total veFXS balance never goes
        // below 1000 gwei, which could cause rounding issues
        // ======================================================
        // Approve
        hoax(dave);
        token.approve(address(vestedFXS), 1e18);

        // Create the lock
        hoax(dave);
        vestedFXS.createLock(dave, 1e18, uint128(block.timestamp) + uint128(WEEK));

        // Step 1: Initial locks, or not
        // ======================================================
        console.log("<<<======== Step 1: Initial locks, or not ========>>>");

        // Print the current timestamp and block
        console.log("<<< Current timestamp is %s. The current block is %s >>>", block.timestamp, block.number);

        // Loop through the users
        // =============================================
        for (uint256 i; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Either create the 1st lock or don't
            // =============================================
            if (_doStep1Create1stLock[_userAddrs[i]]) {
                // Print
                console.log("<<< Doing initial lock for %s >>>", vm.getLabel(_theUser));

                // Impersonate the user
                vm.startPrank(_theUser);

                // Approve
                token.approve(address(vestedFXS), _initialLockAmount[_theUser]);

                // Get the initial lock timestamp
                (_earliestLockEnd, _latestLockEnd) = vestedFXS.getCreateLockTsBounds();
                console.log("<<< _earliestLockEnd: %s >>>", _earliestLockEnd);
                console.log("<<< _latestLockEnd: %s >>>", _latestLockEnd);
                uint128 _lockTimestamp = uint128(block.timestamp + _initialLockTime[_theUser]);

                // Check for expected errors
                if (_lockTimestamp < _earliestLockEnd) {
                    vm.expectRevert(abi.encodeWithSignature("MustBeInAFutureEpochWeek()"));
                    console.log("   ---> Expected to revert [1st vestedFXS.createLock > MustBeInAFutureEpochWeek]");
                } else if (_lockTimestamp >= (_latestLockEnd + WEEK_UINT256)) {
                    vm.expectRevert(abi.encodeWithSignature("LockCanOnlyBeUpToFourYears()"));
                    console.log("   ---> Expected to revert [1st vestedFXS.createLock > LockCanOnlyBeUpToFourYears]");
                } else {
                    // Pre-mark the createLock as having succeeded. If the below reverts with an unexpected error, execution will halt anyways.
                    _userCreate1stLockSucceeded[_theUser] = true;
                }

                // Do the lock
                console.log("<<< Lock length is %s seconds (~%s days) >>>", _initialLockTime[_theUser], _initialLockTime[_theUser] / (DAY));
                console.log("<<< Trying initial lock for %s with %s FXS and %s timestamp >>>", vm.getLabel(_theUser), _initialLockAmount[_theUser], _lockTimestamp);
                (, _createLock1IdTmp) = vestedFXS.createLock(_theUser, _initialLockAmount[_theUser], _lockTimestamp);
                if (_userCreate1stLockSucceeded[_theUser]) {
                    _userCreateLockIds[_theUser].push(_createLock1IdTmp); // #0
                    console.log("<<< %s 1st lock succeeded with ID: %d >>>", vm.getLabel(_theUser), _createLock1IdTmp);
                }

                // Stop impersonation
                vm.stopPrank();
            } else {
                // Print
                console.log("<<< Skipping initial lock for %s >>>", vm.getLabel(_theUser));
            }
        }

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER STEP 1 ========================");

        // Do first time warp
        // ======================================================
        console.log("<<< Do first time warp >>>");

        // Print the current timestamp and block
        console.log("<<< Current timestamp is %s. The current block is %s >>>", block.timestamp, block.number);

        // Do the warp, with or without checkpointing
        if (_doWarpCheckpointing[0]) {
            // Arbitrarily set it to 20 increments
            uint256 _incrementToUse = _warpTimes[0] / 20;

            // Just do one increment if it is too small
            console.log("<<< Advancing %d seconds in %d chunks, WITH checkpointing >>>", _warpTimes[0], _incrementToUse);
            if (_incrementToUse == 0) _incrementToUse = 1;

            // Advance with checkpointing
            advanceTimeWithCheckpointing(_warpTimes[0], _incrementToUse, new bytes(0));
        } else {
            console.log("<<< Advancing %d seconds, WITHOUT checkpointing >>>", _warpTimes[0]);
            mineBlocksBySecond(_warpTimes[0]);
        }

        // Optionally pause, emergencyUnlock, or both
        // ======================================================
        console.log("<<< Optionally pause, emergencyUnlock, or both >>>");

        // Impersonate the admin
        vm.startPrank(vestedFXS.admin());

        // Optionally do the emergency unlock
        if (_doEmergencyUnlock) {
            vestedFXS.activateEmergencyUnlock();
            console.log("   ---> Emergency Unlocked");
        }

        // Optionally do the pause
        if (_doPause) {
            vestedFXS.toggleContractPause();
            console.log("   ---> Paused");
        }

        // Stop impersonating the admin
        vm.stopPrank();

        // Invariant checks
        // ======================================================
        checkInvariants();

        printInfo("======================== AFTER 1ST WARP ========================");

        // Step 2: Combinations of createLock, increaseAmount, and increaseUnlockTime
        // ======================================================
        console.log("<<<======== Step 2: Combinations of createLock, increaseAmount, and increaseUnlockTime ========>>>");

        // Print the current timestamp and block
        console.log("<<< Current timestamp is %s. The current block is %s >>>", block.timestamp, block.number);

        // Loop through the users
        // =============================================
        for (uint256 i; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Impersonate the user
            vm.startPrank(_theUser);

            // Either create the 2nd lock or don't
            // =============================================
            if (_doStep2Create2ndLock[_theUser]) {
                // Print
                console.log("<<< Doing 2nd lock for %s >>>", vm.getLabel(_theUser));

                // Approve
                token.approve(address(vestedFXS), _2ndLockAmount[_theUser]);

                // Get the 2nd lock timestamp
                (_earliestLockEnd, _latestLockEnd) = vestedFXS.getCreateLockTsBounds();
                console.log("<<< _earliestLockEnd: %s >>>", _earliestLockEnd);
                console.log("<<< _latestLockEnd: %s >>>", _latestLockEnd);
                uint128 _lockTimestamp = uint128(block.timestamp + _2ndLockTime[_theUser]);

                // Check for expected errors
                if (_doPause) {
                    vm.expectRevert(abi.encodeWithSignature("OperationIsPaused()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.createLock > OperationIsPaused]");
                } else if (_lockTimestamp < _earliestLockEnd) {
                    vm.expectRevert(abi.encodeWithSignature("MustBeInAFutureEpochWeek()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.createLock > MustBeInAFutureEpochWeek]");
                } else if (_doEmergencyUnlock) {
                    vm.expectRevert(abi.encodeWithSignature("EmergencyUnlockActive()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.createLock > EmergencyUnlockActive]");
                } else if (_lockTimestamp >= (_latestLockEnd + WEEK_UINT256)) {
                    vm.expectRevert(abi.encodeWithSignature("LockCanOnlyBeUpToFourYears()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.createLock > LockCanOnlyBeUpToFourYears]");
                } else {
                    // Pre-mark the createLock as having succeeded. If the below reverts with an unexpected error, execution will halt anyways.
                    _userCreate2ndLockSucceeded[_theUser] = true;
                }

                // Do the lock
                console.log("<<< Lock length is %s seconds (~%s days) >>>", _2ndLockTime[_theUser], _2ndLockTime[_theUser] / (DAY));
                console.log("<<< Trying 2nd lock for %s with %s FXS and %s timestamp >>>", vm.getLabel(_theUser), _2ndLockAmount[_theUser], _lockTimestamp);
                (, _createLock2IdTmp) = vestedFXS.createLock(_theUser, _2ndLockAmount[_theUser], _lockTimestamp);
                if (_userCreate2ndLockSucceeded[_theUser]) {
                    _userCreateLockIds[_theUser].push(_createLock2IdTmp); // #1
                    console.log("<<< %s 2nd lock succeeded with ID: %d >>>", vm.getLabel(_theUser), _createLock2IdTmp);
                }
            } else {
                // Print
                console.log("<<< Skipping 2nd lock for %s >>>", vm.getLabel(_theUser));
            }

            // Either increase the amount of the 1st lock (if you locked in Step 1 and it did not expire yet) or don't
            // =============================================
            if (_doStep1Create1stLock[_theUser] && _doStep2IncreaseAmount[_theUser]) {
                // Print
                console.log("<<< Doing 1st lock increaseAmount for %s >>>", vm.getLabel(_theUser));

                // Fetch the lock
                LockedBalanceExtended memory _extendedLockInfo = vestedFXS.lockedByIdExtended(_theUser, _userCreateLockIds[_theUser][0]);

                // Approve
                token.approve(address(vestedFXS), _increaseAmountAmount[_theUser]);

                // Check for expected errors
                if (_doPause) {
                    vm.expectRevert(abi.encodeWithSignature("OperationIsPaused()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseAmount > OperationIsPaused]");
                } else if (uint256(_extendedLockInfo.end) <= block.timestamp) {
                    vm.expectRevert(abi.encodeWithSignature("LockExpired()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseAmount > LockExpired]");
                } else if (_doEmergencyUnlock) {
                    vm.expectRevert(abi.encodeWithSignature("EmergencyUnlockActive()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseAmount > EmergencyUnlockActive]");
                }

                // Do the increaseAmount
                console.log("<<< Trying increaseAmount for %s with %s FXS >>>", vm.getLabel(_theUser), _increaseAmountAmount[_theUser]);
                vestedFXS.increaseAmount(_increaseAmountAmount[_theUser], _extendedLockInfo.index);
            } else {
                // Print
                console.log("<<< Skipping 1st lock increaseAmount for %s >>>", vm.getLabel(_theUser));
            }

            // Either increase the unlock time of the 1st lock (if you locked in Step 1 and it did not expire yet) or don't
            // =============================================
            if (_doStep1Create1stLock[_theUser] && _doStep2IncreaseUnlockTime[_theUser]) {
                // Print
                console.log("<<< Doing 1st lock increaseUnlockTime for %s >>>", vm.getLabel(_theUser));

                // Fetch the lock
                LockedBalanceExtended memory _extendedLockInfo = vestedFXS.lockedByIdExtended(_theUser, _userCreateLockIds[_theUser][0]);

                // Get the new timestamp
                (_earliestLockEnd, _latestLockEnd) = vestedFXS.getIncreaseUnlockTimeTsBounds(_theUser, _userCreateLockIds[_theUser][0]);
                console.log("<<< _earliestLockEnd: %s >>>", _earliestLockEnd);
                console.log("<<< _latestLockEnd: %s >>>", _latestLockEnd);
                uint128 _lockTimestamp = uint128(block.timestamp + _increaseUnlockTimeTime[_theUser]);

                // Check for expected errors
                if (_doPause) {
                    vm.expectRevert(abi.encodeWithSignature("OperationIsPaused()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseUnlockTime > OperationIsPaused]");
                } else if (uint256(_extendedLockInfo.end) <= block.timestamp) {
                    vm.expectRevert(abi.encodeWithSignature("LockExpired()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseUnlockTime > LockExpired]");
                } else if (_lockTimestamp <= _earliestLockEnd) {
                    vm.expectRevert(abi.encodeWithSignature("MustBeInAFutureEpochWeek()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseUnlockTime > MustBeInAFutureEpochWeek]");
                } else if (_lockTimestamp > _latestLockEnd) {
                    vm.expectRevert(abi.encodeWithSignature("LockCanOnlyBeUpToFourYears()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseUnlockTime > LockCanOnlyBeUpToFourYears]");
                } else if (_doEmergencyUnlock) {
                    vm.expectRevert(abi.encodeWithSignature("EmergencyUnlockActive()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.increaseUnlockTime > EmergencyUnlockActive]");
                }

                // Do the increaseUnlockTime
                console.log("<<< Trying increaseUnlockTime for %s to timestamp %s >>>", vm.getLabel(_theUser), _lockTimestamp);
                vestedFXS.increaseUnlockTime(_lockTimestamp, _extendedLockInfo.index);
            } else {
                // Print
                console.log("<<< Skipping 1st lock increaseUnlockTime for %s >>>", vm.getLabel(_theUser));
            }

            // Either withdraw the 1st lock (if you locked in Step 1 and it expired) or don't
            // =============================================
            if (_userCreate1stLockSucceeded[_theUser] && _doStep2Withdraw1stLock[_theUser]) {
                // Print
                console.log("<<< Doing 1st lock withdrawal for %s >>>", vm.getLabel(_theUser));

                // Fetch the lock
                LockedBalanceExtended memory _extendedLockInfo = vestedFXS.lockedByIdExtended(_theUser, _userCreateLockIds[_theUser][0]);

                // Check for expected errors
                if (_doPause) {
                    vm.expectRevert(abi.encodeWithSignature("OperationIsPaused()"));
                    console.log("   ---> Expected to revert [Step 2 vestedFXS.withdraw > OperationIsPaused]");
                } else if ((uint256(_extendedLockInfo.end) > block.timestamp)) {
                    if (_doEmergencyUnlock) {
                        console.log("   ---> Would normally revert [Step 2 vestedFXS.withdraw > LockDidNotExpire], but _doEmergencyUnlock allows it to succeed");
                        _userWithdraw1stLockSucceeded[_theUser] = true;
                    } else {
                        vm.expectRevert(abi.encodeWithSignature("LockDidNotExpire()"));
                        console.log("   ---> Expected to revert [Step 2 vestedFXS.withdraw > LockDidNotExpire]");
                    }
                } else {
                    // Pre-mark the withdrawal as having succeeded. If the below reverts with an unexpected error, execution will halt anyways.
                    _userWithdraw1stLockSucceeded[_theUser] = true;
                }

                // Do the withdrawal
                vestedFXS.withdraw(_extendedLockInfo.index);
            } else {
                // Print
                console.log("<<< Skipping 1st lock withdrawal for %s >>>", vm.getLabel(_theUser));
            }

            // Stop impersonation
            vm.stopPrank();
        }

        // Invariant checks
        // ======================================================
        _checkInvariantsOptionalEmergency(_doEmergencyUnlock);

        printInfo("======================== AFTER 2ND STEP ========================");
        // Do second time warp
        // ======================================================
        console.log("<<< Do second time warp >>>");

        // Print the current timestamp and block
        console.log("<<< Current timestamp is %s. The current block is %s >>>", block.timestamp, block.number);

        // Do the warp, with or without checkpointing
        if (_doWarpCheckpointing[1]) {
            // Arbitrarily set it to 20 increments
            uint256 _incrementToUse = _warpTimes[1] / 20;

            // Just do one increment if it is too small
            console.log("<<< Advancing %d seconds in %d chunks, WITH checkpointing >>>", _warpTimes[1], _incrementToUse);
            if (_incrementToUse == 0) _incrementToUse = 1;

            // Advance with checkpointing
            bytes memory _failureSig;
            if (_doPause) {
                _failureSig = abi.encodeWithSignature("OperationIsPaused()");
                console.log("   ---> Expected to revert [Checkpoint after 2nd step > OperationIsPaused]");
            } else if (_doEmergencyUnlock) {
                _failureSig = abi.encodeWithSignature("EmergencyUnlockActive()");
                console.log("   ---> Expected to revert [Checkpoint after 2nd step > EmergencyUnlockActive]");
            }
            advanceTimeWithCheckpointing(_warpTimes[1], _incrementToUse, _failureSig);
        } else {
            console.log("<<< Advancing %d seconds, WITHOUT checkpointing >>>", _warpTimes[1]);
            mineBlocksBySecond(_warpTimes[1]);
        }

        // Invariant checks
        // ======================================================
        _checkInvariantsOptionalEmergency(_doEmergencyUnlock);

        // Optionally unpause, if you paused earlier and the fuzz says so
        // ======================================================
        console.log("<<< Optionally unpause >>>");

        // Impersonate the admin
        vm.startPrank(vestedFXS.admin());

        // Optionally unpause
        if (_doPause && _doUnpause) {
            vestedFXS.toggleContractPause();
            console.log("   ---> Unpaused");
        }

        // Stop impersonating the admin
        vm.stopPrank();

        printInfo("======================== AFTER 2ND WARP ========================");

        // Step 3: Withdrawals
        // ======================================================
        console.log("<<<======== Step 3: Withdrawals ========>>>");

        // Print the current timestamp and block
        console.log("<<< Current timestamp is %s. The current block is %s >>>", block.timestamp, block.number);

        // Loop through the users
        // =============================================
        for (uint256 i; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Either withdraw the 1st lock (if you locked in Step 1, it expired, and you didn't already unlock it) or don't
            // =============================================
            if (_userCreate1stLockSucceeded[_theUser] && !_userWithdraw1stLockSucceeded[_theUser] && _doStep3Withdraw1stLock[_theUser]) {
                // Impersonate the user
                vm.startPrank(_theUser);

                // Print
                console.log("<<< Doing 1st lock withdrawal for %s >>>", vm.getLabel(_theUser));

                // Fetch the lock
                LockedBalanceExtended memory _extendedLockInfo = vestedFXS.lockedByIdExtended(_theUser, _userCreateLockIds[_theUser][0]);

                // Check for expected errors
                if (_doPause && !_doUnpause) {
                    vm.expectRevert(abi.encodeWithSignature("OperationIsPaused()"));
                    console.log("   ---> Expected to revert [Step 3 vestedFXS.withdraw 1st lock > OperationIsPaused]");
                } else if (uint256(_extendedLockInfo.end) > block.timestamp) {
                    if (_doEmergencyUnlock) {
                        console.log("   ---> Would normally revert [Step 3 vestedFXS.withdraw 1st lock > LockDidNotExpire], but _doEmergencyUnlock allows it to succeed");
                    } else {
                        vm.expectRevert(abi.encodeWithSignature("LockDidNotExpire()"));
                        console.log("   ---> Expected to revert [Step 3 vestedFXS.withdraw 1st lock > LockDidNotExpire]");
                    }
                }

                // Do the withdrawal
                vestedFXS.withdraw(_extendedLockInfo.index);

                // Stop impersonation
                vm.stopPrank();
            } else {
                // Print
                console.log("<<< Skipping 1st lock withdrawal for %s >>>", vm.getLabel(_theUser));
            }

            // Either withdraw the 2nd lock (if you created it in Step 2, it expired, and you didn't already unlock it) or don't
            // =============================================
            if (_userCreate2ndLockSucceeded[_theUser] && _doStep3Withdraw2ndLock[_theUser]) {
                // Impersonate the user
                vm.startPrank(_theUser);

                // Print
                console.log("<<< Doing 2nd lock withdrawal for %s >>>", vm.getLabel(_theUser));

                // Fetch the lock info
                uint256 _lockIdToUse;
                if (_userCreate1stLockSucceeded[_theUser]) _lockIdToUse = _userCreateLockIds[_theUser][1];
                else _lockIdToUse = _userCreateLockIds[_theUser][0];
                console.log("<<< _lockIdToUse is %d >>>", _lockIdToUse);
                LockedBalanceExtended memory _extendedLockInfo = vestedFXS.lockedByIdExtended(_theUser, _lockIdToUse);
                console.log("<<< Got _extendedLockInfo >>>");

                // Check for expected errors
                if (_doPause) {
                    vm.expectRevert(abi.encodeWithSignature("OperationIsPaused()"));
                    console.log("   ---> Expected to revert [Step 3 vestedFXS.withdraw 2nd lock > OperationIsPaused]");
                } else if (uint256(_extendedLockInfo.end) > block.timestamp) {
                    if (_doEmergencyUnlock) {
                        console.log("   ---> Would normally revert [Step 3 vestedFXS.withdraw 2nd lock > LockDidNotExpire], but _doEmergencyUnlock allows it to succeed");
                    } else {
                        vm.expectRevert(abi.encodeWithSignature("LockDidNotExpire()"));
                        console.log("   ---> Expected to revert [Step 3 vestedFXS.withdraw 2st lock > LockDidNotExpire]");
                    }
                }

                // Do the withdrawal
                vestedFXS.withdraw(_extendedLockInfo.index);

                // Stop impersonation
                vm.stopPrank();
            } else {
                // Print
                console.log("<<< Skipping 2nd lock withdrawal for %s >>>", vm.getLabel(_theUser));
            }
        }

        // // Advance one week
        // advanceTimeWithCheckpointing(7 * DAY, 1 * DAY, new bytes(0));

        // Invariant checks
        // ======================================================
        _checkInvariantsOptionalEmergency(_doEmergencyUnlock);

        printInfo("======================== AFTER 3RD STEP ========================");
        // Do third time warp
        // ======================================================
        console.log("<<< Do third time warp >>>");

        // Print the current timestamp and block
        console.log("<<< Current timestamp is %s. The current block is %s >>>", block.timestamp, block.number);

        // Do the warp, with or without checkpointing
        if (_doWarpCheckpointing[2]) {
            // Arbitrarily set it to 20 increments
            uint256 _incrementToUse = _warpTimes[2] / 20;

            // Just do one increment if it is too small
            console.log("<<< Advancing %d seconds in %d chunks, WITH checkpointing >>>", _warpTimes[2], _incrementToUse);
            if (_incrementToUse == 0) _incrementToUse = 1;

            // Advance with checkpointing
            bytes memory _failureSig;
            if (_doPause && !_doUnpause) {
                _failureSig = abi.encodeWithSignature("OperationIsPaused()");
                console.log("   ---> Expected to revert [Checkpoint after 3rd step > OperationIsPaused]");
            } else if (_doEmergencyUnlock) {
                _failureSig = abi.encodeWithSignature("EmergencyUnlockActive()");
                console.log("   ---> Expected to revert [Checkpoint after 3rd step > EmergencyUnlockActive]");
            }
            advanceTimeWithCheckpointing(_warpTimes[2], _incrementToUse, _failureSig);
        } else {
            console.log("<<< Advancing %d seconds, WITHOUT checkpointing >>>", _warpTimes[2]);
            mineBlocksBySecond(_warpTimes[2]);
        }

        // TODO: CRUDE BALANCE CHECKS OFF. NEED TO DRILL DOWN
        // Maybe the current epoch gets messed up, but subsequent ones are ok?

        // Invariant checks
        // ======================================================
        _checkInvariantsOptionalEmergency(_doEmergencyUnlock);

        printInfo("======================== AFTER 3RD WARP ========================");
    }

    function advanceTimeWithCheckpointing(uint256 _seconds, uint256 _checkpointInterval, bytes memory _failureSig) public {
        // Calculate how many times to checkpoint
        uint256 _numCheckpointChunks = _seconds / _checkpointInterval;
        if (_numCheckpointChunks == 0) _numCheckpointChunks = 1; // Always checkpoint at least once

        // Calculate leftover time
        uint256 _remainderTime = _seconds % _checkpointInterval;

        // Loop and checkpoint
        for (uint128 i = 0; i < _numCheckpointChunks; ++i) {
            // Increase the time and block number
            mineBlocksBySecond(_checkpointInterval);

            // Checkpoint
            if (_failureSig.length > 0) {
                vm.expectRevert(_failureSig);
            }
            vestedFXS.checkpoint();
        }

        // Handle leftover time
        mineBlocksBySecond(_remainderTime);
    }

    function _checkInvariantsOptionalEmergency(bool _isEmergencyUnlock) public {
        if (_isEmergencyUnlock) {
            // Only check balanceOf vs crude balance, as totalSupply() is unreliable
            checkCrudeBalanceOf(alice);
            checkCrudeBalanceOf(bob);
            checkCrudeBalanceOf(claire);
            checkCrudeBalanceOf(dave);

            // You can check FXS too
            checkFXS();
        } else {
            checkBalances();
            checkCrudeBalances();
            checkBalancesAtBlock();
            checkBalancesAtFutureTime(uint256(block.timestamp + 1 * DAY));
            checkFXS();
        }
        console.log("******************************** checkInvariants() done ********************************");
    }

    function checkInvariants() public {
        _checkInvariantsOptionalEmergency(false);
    }

    function checkBalances() public {
        console.log("******************************** checkBalances() start ********************************");
        // Get the current supply and sum
        console.log("---Calling totalSupply---");
        uint256 totalSupply = vestedFXS.totalSupply();
        console.log("---Calling getLastGlobalPoint---");
        Point memory currGlobalPoint = vestedFXS.getLastGlobalPoint();
        console.log("---Global Point (now)---");
        console.log("Global Point bias (now): ", currGlobalPoint.bias);
        console.log("Global Point slope (now): ", currGlobalPoint.slope);
        console.log("Global Point ts (now): ", currGlobalPoint.ts);
        console.log("Global Point blk (now): ", currGlobalPoint.blk);
        console.log("Global Point fxsAmt (now): ", currGlobalPoint.fxsAmt);
        uint256 sum = checkBalanceOf(alice, false);
        sum += checkBalanceOf(bob, false);
        sum += checkBalanceOf(claire, false);
        sum += checkBalanceOf(dave, false);

        // Warp ahead one week and get the future supply and sum
        vm.warp(block.timestamp + WEEK_UINT256);
        uint256 futureTotalSupply = vestedFXS.totalSupply();
        currGlobalPoint = vestedFXS.getLastGlobalPoint();
        console.log("---Global Point (future)---");
        console.log("Global Point bias (future): ", currGlobalPoint.bias);
        console.log("Global Point slope (future): ", currGlobalPoint.slope);
        console.log("Global Point ts (future): ", currGlobalPoint.ts);
        console.log("Global Point blk (future): ", currGlobalPoint.blk);
        console.log("Global Point fxsAmt (future): ", currGlobalPoint.fxsAmt);
        uint256 futureSum = checkBalanceOf(alice, true);
        futureSum += checkBalanceOf(bob, true);
        futureSum += checkBalanceOf(claire, true);
        futureSum += checkBalanceOf(dave, true);
        rewind(WEEK_UINT256);

        // Print
        console.log("____---=== checkBalances() total results ===---____");
        console.log("Current totalSupply: ", totalSupply);
        console.log("Current sum: ", sum);
        console.log("FXS.balanceOf: ", token.balanceOf(address(vestedFXS)));
        console.log("Future TotalSupply: ", futureTotalSupply);
        console.log("Future Sum: ", futureSum);

        // Check
        assertEq(sum, totalSupply, "checkBalances() failed");
    }

    function checkBalancesAtBlock() public {
        console.log("******************************** checkBalancesAtBlock() start ********************************");
        // uint256 blockNo = startBlockNumber + timestamp - startTimestamp;
        uint256 blockNo = block.number;
        // Point memory point;
        // (point.bias, point.slope, point.ts, point.blk, point.fxsAmt) = vestedFXS.pointHistory(1);
        uint256 totalSupply = vestedFXS.totalSupply();
        uint256 sum = checkBalanceOfAtBlock(alice, blockNo);
        sum += checkBalanceOfAtBlock(bob, blockNo);
        sum += checkBalanceOfAtBlock(claire, blockNo);
        sum += checkBalanceOfAtBlock(dave, blockNo);
        //console.log("totalSupply:%d",totalSupply);
        //console.log("sum        :%d",sum);
        if (totalSupply < sum) assertApproxEqRel(sum, totalSupply, 0.000001e18, "checkBalancesAtBlock() failed");
    }

    function checkBalanceOfAtBlock(address user, uint256 blockNo) public returns (uint256 result) {
        for (uint128 i = 0; i < vestedFXS.numLocks(user); ++i) {
            uint256 balance = vestedFXS.balanceOfOneLockAtBlock(user, i, uint128(blockNo));
            result += balance;
        }
    }

    function checkBalanceOfAtTime(address user, uint256 timestamp) public returns (uint256 result) {
        for (uint128 i = 0; i < vestedFXS.numLocks(user); ++i) {
            uint256 balance = vestedFXS.balanceOfOneLockAtTime(user, i, timestamp);
            result += balance;
        }
    }

    function checkBalancesAtFutureTime(uint256 timestamp) public {
        console.log("******************************** checkBalancesAtFutureTime() start ********************************");
        uint256 totalSupply = vestedFXS.totalSupply(timestamp);
        uint256 sum = checkBalanceOfAtTime(alice, timestamp);
        sum += checkBalanceOfAtTime(bob, timestamp);
        sum += checkBalanceOfAtTime(claire, timestamp);
        sum += checkBalanceOfAtTime(dave, timestamp);
        assertEq(sum, totalSupply, "checkBalancesAtFutureTime() failed");
    }

    function checkBalanceOf(address user, bool isFuture) public returns (uint256 result) {
        for (uint128 i = 0; i < vestedFXS.numLocks(user); ++i) {
            uint256 balance = vestedFXS.balanceOfOneLockAtTime(user, i, 0);
            LockedBalance memory lockedBalance;
            (lockedBalance.amount, lockedBalance.end) = vestedFXS.lockedByIndex(user, i);
            int128 balanceViaLockerBalance = lockedBalance.amount;
            int128 timeLeft = int128(lockedBalance.end) - int128(int256(block.timestamp));

            // veFXS should just be the FXS balance if the emergency unlock is on
            if (!vestedFXS.emergencyUnlockActive()) {
                if (timeLeft < 0) timeLeft = 0;
                if (lockedBalance.end > block.timestamp) balanceViaLockerBalance = lockedBalance.amount + ((3 * lockedBalance.amount * timeLeft) / MAXTIME);
            } else {
                console.log("--- Emergency unlock is active, so veFXS = FXS ---");
                timeLeft = 0;
            }

            string memory errorMsg = string(abi.encodePacked("checkBalanceOf() failed for ", vm.getLabel(user)));

            // Get the point
            Point memory lastPoint = vestedFXS.getLastUserPoint(user, i);

            // Print
            if (isFuture) {
                console.log("------- checkBalanceOf (Now) %s, (Lock Index #%d) -------", vm.getLabel(user), i);
            } else {
                console.log("------- checkBalanceOf (Future) %s, (Lock Index #%d) -------", vm.getLabel(user), i);
            }
            console.log("User Point bias: ", lastPoint.bias);
            console.log("User Point slope: ", lastPoint.slope);
            console.log("User Point ts: ", lastPoint.ts);
            console.log("User Point blk: ", lastPoint.blk);
            console.log("User Point fxsAmt: ", lastPoint.fxsAmt);
            console.log("timeLeft: ", timeLeft);
            console.log("lockedBalance.amount: ", lockedBalance.amount);
            console.log("balance: ", balance);
            console.log("balanceViaLockerBalance: ", balanceViaLockerBalance);
            assertApproxEqRel(balance, uint128(balanceViaLockerBalance), 0.015e18, errorMsg);
            result += balance;
        }
    }

    function checkCrudeBalances() public {
        console.log("******************************** checkCrudeBalances() start ********************************");
        uint256 totalSupply = vestedFXS.totalSupply();
        uint256 sum = checkCrudeBalanceOf(alice);
        sum += checkCrudeBalanceOf(bob);
        sum += checkCrudeBalanceOf(claire);
        sum += checkCrudeBalanceOf(dave);
        console.log("vestedFXS.totalSupply(): %d", totalSupply);
        console.log("crudeBalance sum: %d", sum);
        assertApproxEqRel(sum, totalSupply, 0.015e18, "checkCrudeBalances() failed");
    }

    function checkFXS() public {
        console.log("******************************** checkFXS() start ********************************");
        uint256 sum = fxsLocked(alice);
        sum += fxsLocked(bob);
        sum += fxsLocked(claire);
        sum += fxsLocked(dave);
        assertEq(sum, vestedFXS.supply(), "checkFXS() failed (vestedFXS.supply())");
        assertEq(sum, token.balanceOf(address(vestedFXS)), "checkFXS() failed (token.balanceOf(address(vestedFXS))");
    }

    function checkCrudeBalanceOf(address user) public returns (uint256 result) {
        uint256 _actualBalance = vestedFXS.balanceOf(user);
        uint256 _crudeBalance = vestedFXSUtils.getCrudeExpectedVeFXSUser(user);
        console.log("----Crude Balance check for %s--", vm.getLabel(user));
        console.log("_actualBalance: %d", _actualBalance);
        console.log("_crudeBalance: %d", _crudeBalance);
        string memory errorMsg = string(abi.encodePacked("checkCrudeBalanceOf() failed for ", vm.getLabel(user)));
        assertApproxEqRel(_actualBalance, _crudeBalance, 0.015e18, errorMsg);
        result += _crudeBalance;
    }

    function fxsLocked(address user) public returns (uint256 result) {
        int128 sum;
        for (uint128 i = 0; i < vestedFXS.numLocks(user); ++i) {
            (int128 amount,) = vestedFXS.lockedByIndex(user, i);
            sum += amount;
        }
        return uint128(sum);
    }
}
/* solhint-enable */
