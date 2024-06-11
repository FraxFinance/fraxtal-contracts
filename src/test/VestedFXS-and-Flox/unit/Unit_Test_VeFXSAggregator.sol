// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { console } from "frax-std/FraxTest.sol";
import { DecimalStringHelper } from "../helpers/DecimalStringHelper.sol";
import { L1VeFXS } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXS.sol";
import { MintableERC20 } from "../helpers/MintableERC20.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { VestedFXS } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import { YieldDistributor } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/YieldDistributor.sol";

contract Unit_Test_VeFXSAggregator is BaseTestVeFXS {
    using stdStorage for StdStorage;
    using DecimalStringHelper for uint256;

    // Avoid stack-too-deep
    address[4] public _userAddrs = [alice, bob, claire, dave];
    uint256[4] public _tmpL1veFXSBalances;
    uint256[4] public _earnedBefore;
    uint256[4] public _earnedAfterWk1;
    uint256[4] public _earnedAfterWk1WhalePreL1VeFXS;
    uint256[4] public _earnedAfterWk1WhalePostL1VeFXS;
    uint256[4] public _earnedAfterWk2;
    uint256[4] public _ydEligibleVeFXSWk1;
    uint256[4] public _ydEligibleVeFXSWk2;
    mapping(address user => mapping(address lockLocation => uint128[] lockIndices)) _expiringLocks;
    uint256 public _testStartTimestamp;

    // Constants
    // ========================================

    uint256 public constant ONE_DAY_SECS_U256 = 86_400;
    uint256 public constant ONE_WEEK_SECS_U256 = 604_800;
    uint256 public constant ONE_YEAR_SECS_U256 = 31_536_000;
    uint64 public constant ONE_DAY_SECS_U64 = 86_400;
    uint64 public constant ONE_WEEK_SECS_U64 = 604_800;
    uint64 public constant ONE_YEAR_SECS_U64 = 31_536_000;
    uint64 public constant MAXTIME_UINT64 = 4 * 365 * 86_400; // 4 years

    // _expectedVeFXS = uint256(uint128(_fxsAmount + ((3 * _fxsAmount *_timeLeft_i128) / MAXTIME)));
    uint64 public LOCK_SECONDS_2X_U64; // Number of weeks to get a 2x veFXS multiplier
    uint64 public LOCK_SECONDS_3X_U64; // Number of weeks to get a 3x veFXS multiplier
    uint64 public LOCK_SECONDS_4X_U64; // Number of weeks to get a 4x veFXS multiplier

    function setUp() public {
        defaultSetup();

        // Set some variables
        // ======================
        _userAddrs = [alice, bob, claire, dave];
        LOCK_SECONDS_2X_U64 = (1 * MAXTIME_UINT64) / 3;
        LOCK_SECONDS_3X_U64 = (2 * MAXTIME_UINT64) / 3;
        LOCK_SECONDS_4X_U64 = MAXTIME_UINT64;

        // Give users some FXS
        token.mint(alice, 1000e18);
        token.mint(bob, 1000e18);
        token.mint(claire, 1000e18);
        token.mint(dave, 1000e18);

        // Give users some FPIS
        tokenFPIS.mint(alice, 1000e18);
        tokenFPIS.mint(bob, 1000e18);
        tokenFPIS.mint(claire, 1000e18);
        tokenFPIS.mint(dave, 1000e18);

        // Warp to the start of an epoch week
        // ===============================================
        _testStartTimestamp = 604_800 * (1 + (block.timestamp / 604_800));
        _warpToAndRollOne(_testStartTimestamp);

        // Set Yield Distributor rewards
        // ===============================================
        token.mint(address(this), 1000e18);
        token.approve(address(yieldDistributor), 10e18);
        yieldDistributor.notifyRewardAmount(10e18);

        // Set up VestedFXS positions for the users
        // ===============================================
        // Alice will have 2 locks, a long one and a short one
        // veFXS should be 25 + (175 * 4) = 725
        hoax(alice);
        token.approve(address(vestedFXS), 200e18);
        hoax(alice);
        (uint128 _tmpLockindex,) = vestedFXS.createLock(alice, 25e18, uint128(block.timestamp) + uint128(ONE_WEEK_SECS_U64));
        _expiringLocks[alice][address(vestedFXS)].push(_tmpLockindex);
        hoax(alice);
        vestedFXS.createLock(alice, 175e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_4X_U64));
        assertApproxEqRel(vestedFXS.balanceOf(alice), 725e18, HALF_PCT_DELTA, "vestedFXS.balanceOf(alice) should be 725");

        // Bob
        // veFXS should be 200 * 2 = 400
        hoax(bob);
        token.approve(address(vestedFXS), 200e18);
        hoax(bob);
        vestedFXS.createLock(bob, 200e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_2X_U64));
        assertApproxEqRel(vestedFXS.balanceOf(bob), 400e18, HALF_PCT_DELTA, "vestedFXS.balanceOf(bob) should be 400");

        // Skip Claire
        // ...
        assertApproxEqRel(vestedFXS.balanceOf(claire), 0, HALF_PCT_DELTA, "vestedFXS.balanceOf(claire) should be 0");

        // Dave
        // veFXS should be 200 * 2 = 600
        hoax(dave);
        token.approve(address(vestedFXS), 200e18);
        hoax(dave);
        vestedFXS.createLock(dave, 200e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_3X_U64));
        assertApproxEqRel(vestedFXS.balanceOf(dave), 600e18, HALF_PCT_DELTA, "vestedFXS.balanceOf(dave) should be 600");

        // Set up FPISLocker positions for the users
        // ===============================================

        // Alice should have 50 * ((.333 + 1 * (LOCK_SECONDS_2X_U64 / MAXTIME_UINT64)) = 0.666) = 33.333 veFXS
        hoax(alice);
        tokenFPIS.approve(address(fpisLocker), 50e18);
        hoax(alice);
        fpisLocker.createLock(alice, 50e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_2X_U64));
        assertApproxEqRel(fpisLocker.balanceOf(alice), 33.333e18, HALF_PCT_DELTA, "fpisLocker.balanceOf(alice) should be 33.333");

        // Bob should have 50 * ((.333 + 1 * (LOCK_SECONDS_4X_U64 / MAXTIME_UINT64)) = 1.333) = 66.6666 veFXS
        hoax(bob);
        tokenFPIS.approve(address(fpisLocker), 50e18);
        hoax(bob);
        fpisLocker.createLock(bob, 50e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_4X_U64));
        assertApproxEqRel(fpisLocker.balanceOf(bob), 66.666e18, HALF_PCT_DELTA, "fpisLocker.balanceOf(bob) should be 66.666");

        // Skip Claire again
        // ...
        assertApproxEqRel(fpisLocker.balanceOf(claire), 0, HALF_PCT_DELTA, "fpisLocker.balanceOf(claire) should be 0");

        // Dave has a position that will expire soon
        hoax(dave);
        tokenFPIS.approve(address(fpisLocker), 50e18);
        hoax(dave);
        (_tmpLockindex,) = fpisLocker.createLock(dave, 50e18, uint128(block.timestamp) + uint128(ONE_WEEK_SECS_U64));
        _expiringLocks[dave][address(fpisLocker)].push(_tmpLockindex);
        assertApproxEqRel(fpisLocker.balanceOf(dave), 16.666e18, 0.015e18, "fpisLocker.balanceOf(dave) should be about 16.666");

        // Force-prove some L1veFXS positions for the users
        // ===============================================

        // Set up the addresses
        // Skip Dave
        address[] memory _l1veFXSAddresses = new address[](3);
        _l1veFXSAddresses[0] = alice;
        _l1veFXSAddresses[1] = bob;
        _l1veFXSAddresses[2] = claire;

        // Set up the LockedBalances
        L1VeFXS.LockedBalance[] memory _l1veFXSLockedBalances = new L1VeFXS.LockedBalance[](3);

        // Alice should have 200 veFXS
        _l1veFXSLockedBalances[0] = L1VeFXS.LockedBalance({ amount: 100e18, end: uint64(block.timestamp) + LOCK_SECONDS_2X_U64, blockTimestamp: uint64(block.timestamp) - ONE_WEEK_SECS_U64 });

        // Bob should have 0 veFXS because he is expired
        _l1veFXSLockedBalances[1] = L1VeFXS.LockedBalance({ amount: 100e18, end: uint64(block.timestamp) - ONE_DAY_SECS_U64, blockTimestamp: uint64(block.timestamp) - ONE_WEEK_SECS_U64 });

        // Claire should have 400 veFXS
        _l1veFXSLockedBalances[2] = L1VeFXS.LockedBalance({ amount: 100e18, end: uint64(block.timestamp) + LOCK_SECONDS_4X_U64, blockTimestamp: uint64(block.timestamp) - ONE_WEEK_SECS_U64 });

        // Dave doesn't have an entry at all
        // ...

        // Fake-update the Mainnet total veFXS supply that the veFXSAggregator will use
        // Based on the above users
        l1VeFXSTotalSupplyOracle.updateInfo(600e18, uint128(block.number), uint128(block.timestamp) - uint128(ONE_WEEK_SECS_U64));

        // Admin override set the balances on L1veFXS
        l1VeFXS.adminProofVeFXS(_l1veFXSAddresses, _l1veFXSLockedBalances);

        // Check that the veFXS balances are correct on L1veFXS
        assertEq(l1VeFXS.balanceOf(alice), 200e18, "l1VeFXS.balanceOf(alice) should be 200");
        assertEq(l1VeFXS.balanceOf(bob), 0, "l1VeFXS.balanceOf(bob) should be 0 because he is expired");
        assertEq(l1VeFXS.balanceOf(claire), 400e18, "l1VeFXS.balanceOf(alice) should be 400");

        // Set up Additional VestedFXS positions for the users
        // ===============================================
        // Alice
        // veFXS should be 40
        hoax(alice);
        token.approve(address(addlVeFXS), 10e18);
        hoax(alice);
        addlVeFXS.createLock(alice, 10e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_4X_U64));
        assertApproxEqRel(addlVeFXS.balanceOf(alice), 40e18, HALF_PCT_DELTA, "addlVeFXS.balanceOf(alice) should be 40");

        // Bob
        // veFXS should be 80
        hoax(bob);
        token.approve(address(addlVeFXS), 40e18);
        hoax(bob);
        addlVeFXS.createLock(bob, 40e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_2X_U64));
        assertApproxEqRel(addlVeFXS.balanceOf(bob), 80e18, HALF_PCT_DELTA, "addlVeFXS.balanceOf(bob) should be 80");

        // Claire
        // veFXS should be 100. Position will expire soon
        hoax(claire);
        token.approve(address(addlVeFXS), 100e18);
        hoax(claire);
        (_tmpLockindex,) = addlVeFXS.createLock(claire, 100e18, uint128(block.timestamp) + uint128(ONE_WEEK_SECS_U64));
        _expiringLocks[claire][address(addlVeFXS)].push(_tmpLockindex);
        assertApproxEqRel(addlVeFXS.balanceOf(claire), 100e18, 0.015e18, "addlVeFXS.balanceOf(claire) should be 100");

        // Skip Dave
        // ...
        assertApproxEqRel(addlVeFXS.balanceOf(dave), 0, HALF_PCT_DELTA, "addlVeFXS.balanceOf(dave) should be 0");

        // Check aggregate balances
        // ===============================================
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(alice), 998.33333333e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(alice) should be 998.333");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(bob), 546.66666666e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(bob) should be 546.666");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(claire), 500e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(claire) should be 500");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(dave), 616.66666666e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(dave) should be 616.666");

        // Checkpoint everyone on the Yield Distributor and make sure all veFXS is currently eligible for yield
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Checkpoint the user
            yieldDistributor.checkpointOtherUser(_theUser);

            // Get their eligible veFXS
            (uint256 _eligVeFXS, uint256 _storedEndTs) = yieldDistributor.eligibleCurrentVeFXS(_theUser);

            // All of their veFXS should currently be eligible
            string memory _errorMsg = string(abi.encodePacked("[", vm.getLabel(_theUser), "]: Eligible veFXS does not match aggregator total"));
            assertApproxEqRel(_eligVeFXS, veFXSAggregator.ttlCombinedVeFXS(_theUser), HALF_PCT_DELTA, _errorMsg);
        }

        // Print some veFXS totals
        console.log("AGG ttlCombinedVeFXSTotalSupply: ", veFXSAggregator.ttlCombinedVeFXSTotalSupply().decimalString(18, false));
        console.log("YD totalVeFXSParticipating: ", yieldDistributor.totalVeFXSParticipating().decimalString(18, false));
        console.log("YD totalComboVeFXSSupplyStored: ", yieldDistributor.totalComboVeFXSSupplyStored().decimalString(18, false));
        console.log("YD fractionParticipating (%%): ", (yieldDistributor.fractionParticipating() * 100).decimalString(6, true));

        // The three totals should all match
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXSTotalSupply(), 2661.666e18, HALF_PCT_DELTA, "[setUp] veFXSAggregator.ttlCombinedVeFXSTotalSupply should match the sum of the users");
        assertApproxEqRel(yieldDistributor.totalVeFXSParticipating(), 2661.666e18, HALF_PCT_DELTA, "[setUp] yieldDistributor.totalVeFXSParticipating should match the sum of the users");
        assertApproxEqRel(yieldDistributor.totalComboVeFXSSupplyStored(), 2661.666e18, HALF_PCT_DELTA, "[setUp] yieldDistributor.totalComboVeFXSSupplyStored should match the sum of the users");

        // Total fraction participating in the YD should be 100%
        assertEq(yieldDistributor.fractionParticipating(), 1e6, "Total fraction participating in the YD should be 100%");

        // Check some other things
        {
            // For code coverage
            address[] memory _addresses = veFXSAggregator.allAddlVeContractsAddresses();
            assertEq(_addresses[0], address(addlVeFXS), "allAddlVeContractsAddresses should have address(addlVeFXS)");

            // For code coverage
            uint256 _length = veFXSAggregator.allAddlVeContractsLength();
            assertEq(_length, 1, "allAddlVeContractsLength should be 1");
        }

        // Print user locks
        printActiveLocks();
    }

    function printActiveLocks() public {
        // Print
        console.log(unicode"\n🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳 ACTIVE LOCKS 🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳");

        for (uint256 j = 0; j < _userAddrs.length; j++) {
            // Get the user
            address _theUser = _userAddrs[j];

            // Print
            console.log(unicode"🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱 %s 🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱", vm.getLabel(_theUser));

            // Fetch the active locks for the user
            LockedBalanceExtendedV2[] memory _activeLocks = veFXSAggregator.getAllCurrActiveLocks(_theUser, true);

            // Loop through all of the locks and print
            for (uint256 i = 0; i < _activeLocks.length; i++) {
                // Get the individual lock
                LockedBalanceExtendedV2 memory _theLock = _activeLocks[i];

                // Print the info
                console.log("~~~~~ LOCK #%s ~~~~~", i);
                console.log("Status: Active");
                console.log("id: %s", _theLock.id);
                console.log("index: %s", _theLock.index);
                console.log("amount (dec'd): %s", (uint256(uint128(_theLock.amount))).decimalString(18, false));
                console.log("end: %s", _theLock.end);
                console.log("location: %s", vm.getLabel(_theLock.location));
                console.log("estimatedCurrLockVeFXS: %s", _theLock.estimatedCurrLockVeFXS.decimalString(18, false));
            }
        }
    }

    function printExpiredLocks() public {
        // Print
        console.log(unicode"\n🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦 EXPIRED LOCKS 🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦");

        for (uint256 j = 0; j < _userAddrs.length; j++) {
            // Get the user
            address _theUser = _userAddrs[j];

            // Print
            console.log(unicode"💀💀💀💀💀💀💀💀 %s 💀💀💀💀💀💀💀💀", vm.getLabel(_theUser));

            // Fetch the expired locks for the user
            LockedBalanceExtendedV2[] memory _expiredLocks = veFXSAggregator.getAllExpiredLocks(_theUser);

            // Loop through all of the locks and print
            for (uint256 i = 0; i < _expiredLocks.length; i++) {
                // Get the individual lock
                LockedBalanceExtendedV2 memory _theLock = _expiredLocks[i];

                // Print the info
                console.log("~~~~~ LOCK #%s ~~~~~", i);
                console.log("Status: Expired");
                console.log("id: %s", _theLock.id);
                console.log("index: %s", _theLock.index);
                console.log("amount (dec'd): %s", (uint256(uint128(_theLock.amount))).decimalString(18, false));
                console.log("end: %s", _theLock.end);
                console.log("location: %s", vm.getLabel(_theLock.location));
                console.log("estimatedCurrLockVeFXS: %s", _theLock.estimatedCurrLockVeFXS.decimalString(18, false));
            }
        }
    }

    function printMiscVeFXSInfo(string memory titleString) public returns (uint256[4] memory _vestedFXSBalances, uint256[4] memory _fpisLockerBalances, uint256[4] memory _l1veFXSBalances, uint256[4] memory _addlVeFXSBalances, uint256[4] memory _ttlCombinedVeFXS, uint256[4] memory _ydEligibleVeFXS, uint256[4] memory _ydStoredEndTs, uint256[4] memory _ydEarned) {
        // Print the title
        console.log("");
        console.log(titleString);

        // Fetch all veFXS balances
        // ------------------------------------

        // Loop through all of the users
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Get the balances
            _vestedFXSBalances[i] = vestedFXS.balanceOf(_theUser);
            _fpisLockerBalances[i] = fpisLocker.balanceOf(_theUser);
            _l1veFXSBalances[i] = l1VeFXS.balanceOf(_theUser);
            _addlVeFXSBalances[i] = addlVeFXS.balanceOf(_theUser);
            _ttlCombinedVeFXS[i] = veFXSAggregator.ttlCombinedVeFXS(_theUser);
            (_ydEligibleVeFXS[i], _ydStoredEndTs[i]) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
            _ydEarned[i] = yieldDistributor.earned(_theUser);

            // Verify that the sums match the aggregated total
            string memory _errorMsg = string(abi.encodePacked("[", vm.getLabel(_theUser), "]: Sum of veFXS sources does not match aggregator total"));
            assertApproxEqRel(_l1veFXSBalances[i] + _fpisLockerBalances[i] + _vestedFXSBalances[i] + _addlVeFXSBalances[i], _ttlCombinedVeFXS[i], HALF_PCT_DELTA, _errorMsg);

            // Print user totals
            console.log("-------------- %s TOTALS --------------", vm.getLabel(_theUser));
            console.log("VestedFXS: %s", _vestedFXSBalances[i].decimalString(18, false));
            console.log("FPISLocker: %s", _fpisLockerBalances[i].decimalString(18, false));
            console.log("L1veFXS: %s", _l1veFXSBalances[i].decimalString(18, false));
            console.log("AddlVeFXS: %s", _addlVeFXSBalances[i].decimalString(18, false));
            console.log("Total Combined VeFXS (aggregator): %s", _ttlCombinedVeFXS[i].decimalString(18, false));
            console.log("YD Eligible VeFXS: %s", _ydEligibleVeFXS[i].decimalString(18, false));
            console.log("YD Stored End Timestamp: %s", _ydStoredEndTs[i]);
            console.log("YD Earned: %s", _ydEarned[i].decimalString(18, false));
        }

        // Print some veFXS totals
        console.log("<<<<<<<<<<<<<<<<<<<< COMBINED TOTALS >>>>>>>>>>>>>>>>>>>>");
        console.log("AGG ttlCombinedVeFXSTotalSupply: ", veFXSAggregator.ttlCombinedVeFXSTotalSupply().decimalString(18, false));
        console.log("YD totalVeFXSParticipating: ", yieldDistributor.totalVeFXSParticipating().decimalString(18, false));
        console.log("YD totalComboVeFXSSupplyStored: ", yieldDistributor.totalComboVeFXSSupplyStored().decimalString(18, false));
        console.log("YD fractionParticipating (%%): ", (yieldDistributor.fractionParticipating() * 100).decimalString(6, true));
    }

    function test_getAllCurrActiveLocksNoRevert() public {
        // Should not revert for a user that has no locks
        veFXSAggregator.getAllCurrActiveLocks(frank, true);

        // Frank does a short lock
        token.mint(frank, 1000e18);
        hoax(frank);
        token.approve(address(vestedFXS), 200e18);
        hoax(frank);
        vestedFXS.createLock(frank, 25e18, uint128(block.timestamp) + uint128(ONE_WEEK_SECS_U64));

        // Warp past the lock expiry
        _warpToAndRollOne(uint128(block.timestamp) + (3 * ONE_WEEK_SECS_U256) + 1);

        // Should not revert for a user that only has expired locks
        veFXSAggregator.getAllCurrActiveLocks(frank, true);
    }

    function test_MiscAdminFunctions() public {
        setUp();

        // Set the addresses to the same ones, nothing should change
        address[6] memory _veAddresses = [address(vestedFXS), address(vestedFXSUtils), address(fpisLocker), address(fpisLockerUtils), address(l1VeFXS), address(l1VeFXSTotalSupplyOracle)];
        veFXSAggregator.setAddresses(_veAddresses);

        // The three totals should all match the original setup
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXSTotalSupply(), 2661.666e18, HALF_PCT_DELTA, "[MAF] veFXSAggregator.ttlCombinedVeFXSTotalSupply should match the sum of the users");
        assertApproxEqRel(yieldDistributor.totalVeFXSParticipating(), 2661.666e18, HALF_PCT_DELTA, "[MAF] yieldDistributor.totalVeFXSParticipating should match the sum of the users");
        assertApproxEqRel(yieldDistributor.totalComboVeFXSSupplyStored(), 2661.666e18, HALF_PCT_DELTA, "[MAF] yieldDistributor.totalComboVeFXSSupplyStored should match the sum of the users");

        // Try to add a non-compliant additional veFXS source (should fail)
        vm.expectRevert();
        veFXSAggregator.addAddlVeFXSContract(address(flox));

        // Remove an existing additional veFXS source
        veFXSAggregator.removeAddlVeFXSContract(address(addlVeFXS));

        // Bulk checkpoint the users
        address[] memory _userAddrs = new address[](4);
        _userAddrs[0] = alice;
        _userAddrs[1] = bob;
        _userAddrs[2] = claire;
        _userAddrs[3] = dave;
        yieldDistributor.bulkCheckpointOtherUsers(_userAddrs);

        // The three totals should have gone now that the additional veFXS source was removed
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXSTotalSupply(), 2441.666e18, HALF_PCT_DELTA, "[MAF] veFXSAggregator.ttlCombinedVeFXSTotalSupply should have decreased after the addl veFXS source was removed");
        assertApproxEqRel(yieldDistributor.totalVeFXSParticipating(), 2441.666e18, HALF_PCT_DELTA, "[MAF] yieldDistributor.totalVeFXSParticipating should have decreased after the addl veFXS source was removed");
        assertApproxEqRel(yieldDistributor.totalComboVeFXSSupplyStored(), 2441.666e18, HALF_PCT_DELTA, "[MAF] yieldDistributor.totalComboVeFXSSupplyStored should have decreased after the addl veFXS source was removed");
    }

    function test_recoverERC20() public {
        setUp();

        // Give the aggregator some FXS
        token.mint(address(veFXSAggregator), 1000e18);

        // Random user Claire should not be able to recover tokens
        hoax(claire);
        vm.expectRevert(VeFXSAggregator.NotOwnerOrTimelock.selector);
        veFXSAggregator.recoverERC20(address(token), 1e18);

        // Owner should be able to recover tokens
        veFXSAggregator.recoverERC20(address(token), 1e18);
    }

    function test_SetTimelock() public {
        setUp();

        // Set Alice as the timelock
        veFXSAggregator.setTimelock(alice);

        assertEq(veFXSAggregator.timelockAddress(), alice);

        console.log("<<<Alice sets Bob as TL>>>");
        hoax(alice);
        veFXSAggregator.setTimelock(bob);
        assertEq(veFXSAggregator.timelockAddress(), bob);

        console.log("<<<Bob sets Alice as TL>>>");
        hoax(bob);
        veFXSAggregator.setTimelock(alice);
        assertEq(veFXSAggregator.timelockAddress(), alice);

        console.log("<<<Bob tries to set Alice as TL again but fails>>>");
        hoax(bob);
        vm.expectRevert(VeFXSAggregator.NotOwnerOrTimelock.selector);
        veFXSAggregator.setTimelock(alice);
    }

    function test_DifferentTimesOne() public {
        setUp();

        printMiscVeFXSInfo("==================== INITIAL BALANCES ====================");

        // Warp right before one week
        _warpToAndRollOne(_testStartTimestamp + (ONE_WEEK_SECS_U256) - 1);

        (,,,,,,, _earnedBefore) = printMiscVeFXSInfo("==================== RIGHT BEFORE WEEK 1 END ====================");

        // Warp right after the end of week 1 (start of week 2)
        _warpToAndRollOne(_testStartTimestamp + (ONE_WEEK_SECS_U256) + 1);

        (,, _tmpL1veFXSBalances,,, _ydEligibleVeFXSWk1,, _earnedAfterWk1) = printMiscVeFXSInfo("==================== RIGHT AFTER WEEK 1 END ====================");

        // Earnings should not have been zeroed out for people that have 0 eligible veFXS now
        // It will be halved for them though because of the midpoint
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            if (_ydEligibleVeFXSWk1[i] == 0) {
                string memory _errorMsg = string(abi.encodePacked("[", vm.getLabel(_theUser), "]: Lock expiration should only half, not zero, YD earnings"));
                assertApproxEqRel(_earnedBefore[i] / 2, _earnedAfterWk1[i], HALF_PCT_DELTA, _errorMsg);
            }
        }

        // Mega whale enters mainnet veFXS with 10,000,000 veFXS
        // He doesn't prove on L1VeFXS yet though, but the L1VeFXSTotalSupplyOracle catches it
        {
            // Account for the 4 normal users first
            // Should factor in decay
            uint256 _expectedL1VeFXSTotalSupply = _tmpL1veFXSBalances[0] + _tmpL1veFXSBalances[1] + _tmpL1veFXSBalances[2] + _tmpL1veFXSBalances[3];

            // Add in the whale
            _expectedL1VeFXSTotalSupply += 10_000_000e18;

            // Update the L1VeFXSTotalSupplyOracle
            l1VeFXSTotalSupplyOracle.updateInfo(_expectedL1VeFXSTotalSupply, uint128(block.number), uint128(block.timestamp));
        }

        (,,,,,,, _earnedAfterWk1WhalePreL1VeFXS) = printMiscVeFXSInfo("==================== AFTER MAINNET WHALE ENTERS (BEFORE HE PROVES ON L1VeFXS ) ====================");

        // The mainnet whale entry alone with l1VeFXSTotalSupplyOracle should not have done anything to the existing user earnings
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Check earnings
            string memory _errorMsg = string(abi.encodePacked("[", vm.getLabel(_theUser), "]: Mainnet whale entry should not have cut earnings"));
            assertEq(_earnedAfterWk1[i], _earnedAfterWk1WhalePreL1VeFXS[i], _errorMsg);
        }

        // Whale proves on L1veFXS and also checkpoints on the YD
        {
            // Set up the addresses
            address[] memory _l1veFXSAddresses = new address[](1);
            _l1veFXSAddresses[0] = whale;

            // Set up the LockedBalances
            L1VeFXS.LockedBalance[] memory _l1veFXSLockedBalances = new L1VeFXS.LockedBalance[](1);
            _l1veFXSLockedBalances[0] = L1VeFXS.LockedBalance({ amount: 2_500_000e18, end: uint64(block.timestamp) + LOCK_SECONDS_4X_U64, blockTimestamp: uint64(block.timestamp) - ONE_WEEK_SECS_U64 });

            // Admin actually does this for the whale here, but in prod he would do it himself
            l1VeFXS.adminProofVeFXS(_l1veFXSAddresses, _l1veFXSLockedBalances);

            // Checkpoint the whale
            yieldDistributor.checkpointOtherUser(whale);
        }

        (,,,,,,, _earnedAfterWk1WhalePostL1VeFXS) = printMiscVeFXSInfo("=============== AFTER MAINNET WHALE PROVES ON L1VeFXS AND CHECKPOINTS ON THE YD ===============");

        // The whale proving on L1veFXS and checkpointing on the YD should still not effect existing earnings
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Check earnings
            string memory _errorMsg = string(abi.encodePacked("[", vm.getLabel(_theUser), "]: Mainnet whale proving on L1veFXS and checkpointing on the YD should not have cut earnings"));
            assertEq(_earnedAfterWk1WhalePreL1VeFXS[i], _earnedAfterWk1WhalePostL1VeFXS[i], _errorMsg);
        }

        // Set Yield Distributor rewards again
        token.approve(address(yieldDistributor), 10e18);
        yieldDistributor.notifyRewardAmount(10e18);

        // Warp right after the end of week 2 (start of week 3)
        _warpToAndRollOne(_testStartTimestamp + (2 * ONE_WEEK_SECS_U256) + 1);

        (,,,,, _ydEligibleVeFXSWk2,, _earnedAfterWk2) = printMiscVeFXSInfo("==================== START OF WEEK 3 ====================");

        // Other user earnings should have been heavily suppressed due to the whale
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            if (_ydEligibleVeFXSWk2[i] > 0) {
                // Get the user
                address _theUser = _userAddrs[i];

                // Check earnings
                string memory _errorMsg = string(abi.encodePacked("[", vm.getLabel(_theUser), "]: Whale should have suppressed earnings"));
                assertApproxEqRel(_earnedAfterWk1WhalePreL1VeFXS[i], _earnedAfterWk2[i], ONE_PCT_DELTA, _errorMsg);
            }
        }

        // Whale should have earned the lion's share of the rewards
        assertApproxEqRel(yieldDistributor.earned(whale), 10e18, ONE_PCT_DELTA, "Whale should have earned nearly all of week 2's yield");

        printMiscVeFXSInfo("==================== BEFORE WITHDRAWING EXPIRED LOCKS ====================");

        printExpiredLocks();

        // Withdraw the expired locks
        hoax(alice);
        vestedFXS.withdraw(_expiringLocks[alice][address(vestedFXS)][0]);
        hoax(claire);
        addlVeFXS.withdraw(_expiringLocks[claire][address(addlVeFXS)][0]);
        hoax(dave);
        fpisLocker.withdraw(_expiringLocks[dave][address(fpisLocker)][0]);

        printMiscVeFXSInfo("==================== AFTER WITHDRAWING EXPIRED LOCKS ====================");

        printExpiredLocks();
    }
}
