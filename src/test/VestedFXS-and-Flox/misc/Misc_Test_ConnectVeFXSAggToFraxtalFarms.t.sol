// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import { console } from "frax-std/FraxTest.sol";
import { DecimalStringHelper } from "../helpers/DecimalStringHelper.sol";
import { FPISLocker } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLocker.sol";
import { IFraxswapPair } from "src/contracts/VestedFXS-and-Flox/interfaces/IFraxswapPair.sol";
import { IFraxtalFarm } from "src/contracts/VestedFXS-and-Flox/interfaces/IFraxtalFarm.sol";
import { IveFXSEvents } from "src/contracts/VestedFXS-and-Flox/VestedFXS/IveFXSEvents.sol";
import { IveFXSStructs } from "src/contracts/VestedFXS-and-Flox/VestedFXS/IveFXSStructs.sol";
import { L1VeFXS } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXS.sol";
import { MintableERC20 } from "../helpers/MintableERC20.sol";
import { Proxy } from "src/script/VestedFXS-and-Flox/Proxy.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { VestedFXS } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import { YieldDistributor } from "../../../contracts/VestedFXS-and-Flox/VestedFXS/YieldDistributor.sol";
import "src/Constants.sol" as Constants;

contract Misc_Test_ConnectVeFXSAggToFraxtalFarms is FraxTest, IveFXSEvents, IveFXSStructs {
    using stdStorage for StdStorage;
    using DecimalStringHelper for uint256;

    // Avoid stack-too-deep
    address[3] public _userAddrs;
    uint256 public _testStartTimestamp;
    mapping(address user => mapping(address lockLocation => uint128[] lockIndices)) _expiringLocks;

    // ERC20s
    // =========================================
    MintableERC20 public frax = MintableERC20(Constants.FraxtalMainnet.FRAX_ERC20);
    MintableERC20 public fxs = MintableERC20(Constants.FraxtalMainnet.FXS_ERC20);
    IFraxtalFarm public farm = IFraxtalFarm(0x8fE4C7F2eF79AEDd8A6e40398a17ed4DaE18Ee25);
    IFraxswapPair public lp = IFraxswapPair(0xb4dA8dA10ffF1F6127ab71395053Aa1d499b503F);

    // veFXS
    // =========================================
    FPISLocker public fpisLocker = FPISLocker(Constants.FraxtalMainnet.FPIS_LOCKER_PROXY);
    L1VeFXS public l1VeFXS = L1VeFXS(Constants.FraxtalMainnet.L1VEFXS_PROXY);
    VestedFXS public vestedFXS = VestedFXS(Constants.FraxtalMainnet.VESTED_FXS_PROXY);
    VeFXSAggregator public veFXSAggregator = VeFXSAggregator(Constants.FraxtalMainnet.VEFXS_AGGREGATOR_PROXY);
    YieldDistributor public yieldDistributor = YieldDistributor(Constants.FraxtalMainnet.YIELD_DISTRIBUTOR_PROXY);

    // Misc
    // =========================================

    uint256 public alicePrivateKey;
    address payable public alice;
    uint256 public bobPrivateKey;
    address payable public bob;
    uint256 public clairePrivateKey;
    address payable public claire;

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

    uint256 public HALF_PCT_DELTA = 0.005e18;
    uint256 public ONE_PCT_DELTA = 0.01e18;

    function defaultSetup() public {
        // Switch to Fraxtal
        vm.createSelectFork(vm.envString("FRAXTAL_RPC_URL"), 8_559_275);

        // Set some variables
        // ======================
        LOCK_SECONDS_2X_U64 = (1 * MAXTIME_UINT64) / 3;
        LOCK_SECONDS_3X_U64 = (2 * MAXTIME_UINT64) / 3;
        LOCK_SECONDS_4X_U64 = MAXTIME_UINT64;

        // Set up Alice
        alicePrivateKey = 0xA11CE;
        alice = payable(vm.addr(alicePrivateKey));
        vm.label(alice, "Alice");

        // Set up Bob
        bobPrivateKey = 0xB0B;
        bob = payable(vm.addr(bobPrivateKey));
        vm.label(bob, "Bob");

        // Set up Claire
        clairePrivateKey = 0xc0;
        claire = payable(vm.addr(clairePrivateKey));
        vm.label(claire, "Claire");

        // Tracking
        _userAddrs = [alice, bob, claire];

        // Labels
        vm.label(address(frax), "frax");
        vm.label(address(fxs), "fxs");
        vm.label(address(farm), "farm");
        vm.label(address(lp), "lp");
        vm.label(address(fpisLocker), "fpisLocker");
        vm.label(address(l1VeFXS), "l1VeFXS");
        vm.label(address(vestedFXS), "vestedFXS");
        vm.label(address(veFXSAggregator), "veFXSAggregator");
        vm.label(address(yieldDistributor), "yieldDistributor");

        // Give users some LP
        vm.startPrank(Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG);
        lp.transfer(alice, 100e18);
        lp.transfer(bob, 100e18);
        lp.transfer(claire, 100e18);

        // Give users some FXS
        fxs.transfer(address(this), 10_000e18);
        fxs.transfer(alice, 10_000e18);
        fxs.transfer(bob, 10_000e18);
        fxs.transfer(claire, 10_000e18);
        vm.stopPrank();

        // Upgrade the implementation on the VeFXSAggregator
        hoax(Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG);
        Proxy(payable(address(veFXSAggregator))).upgradeTo(Constants.FraxtalMainnet.VEFXS_AGGREGATOR_IMPL);

        // Check a user's balance
        assertApproxEqRel(veFXSAggregator.balanceOf(0x5180db0237291A6449DdA9ed33aD90a38787621c), 2129.834e18, HALF_PCT_DELTA, "IC VeFXSAggregator balanceOf should be ~ 2129.834e18");

        // Warp to the start of an epoch week
        _testStartTimestamp = 604_800 * (1 + (block.timestamp / 604_800));
        _warpToAndRollOne(_testStartTimestamp);

        // Set the veFXS for the farm to the aggregator
        hoax(farm.owner());
        farm.setVeFXS(address(veFXSAggregator));

        // Set up VestedFXS positions for the users
        // ===============================================
        // Alice
        // veFXS should be 100 * 2 = 200
        hoax(alice);
        fxs.approve(address(vestedFXS), 100e18);
        hoax(alice);
        (uint128 _tmpLockindex,) = vestedFXS.createLock(alice, 100e18, uint128(block.timestamp) + LOCK_SECONDS_2X_U64);
        _expiringLocks[alice][address(vestedFXS)].push(_tmpLockindex);

        assertApproxEqRel(vestedFXS.balanceOf(alice), 200e18, HALF_PCT_DELTA, "vestedFXS.balanceOf(alice) should be 200");

        // Bob
        // veFXS should be 200 * 3 = 600
        hoax(bob);
        fxs.approve(address(vestedFXS), 200e18);
        hoax(bob);
        vestedFXS.createLock(bob, 200e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_3X_U64));
        assertApproxEqRel(vestedFXS.balanceOf(bob), 600e18, HALF_PCT_DELTA, "vestedFXS.balanceOf(bob) should be 600");

        // Claire
        // veFXS should be 2500 * 4 = 10000
        hoax(claire);
        fxs.approve(address(vestedFXS), 2500e18);
        hoax(claire);
        vestedFXS.createLock(claire, 2500e18, uint128(block.timestamp) + uint128(LOCK_SECONDS_4X_U64));
        assertApproxEqRel(vestedFXS.balanceOf(claire), 10_000e18, HALF_PCT_DELTA, "vestedFXS.balanceOf(claire) should be 10000");

        // Check aggregate balances
        // ===============================================
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(alice), 200e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(alice) should be 200");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(bob), 600e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(bob) should be 600");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(claire), 10_000e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(claire) should be 10000");

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

    function printMiscVeFXSInfo(string memory titleString) public returns (uint256[4] memory _vestedFXSBalances, uint256[4] memory _fpisLockerBalances, uint256[4] memory _l1veFXSBalances, uint256[4] memory _ttlCombinedVeFXS, uint256[4] memory _ydEligibleVeFXS, uint256[4] memory _ydStoredEndTs, uint256[4] memory _ydEarned) {
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
            _ttlCombinedVeFXS[i] = veFXSAggregator.ttlCombinedVeFXS(_theUser);
            (_ydEligibleVeFXS[i], _ydStoredEndTs[i]) = yieldDistributor.eligibleCurrentVeFXS(_theUser);
            _ydEarned[i] = yieldDistributor.earned(_theUser);

            // Verify that the sums match the aggregated total
            string memory _errorMsg = string(abi.encodePacked("[", vm.getLabel(_theUser), "]: Sum of veFXS sources does not match aggregator total"));
            assertApproxEqRel(_l1veFXSBalances[i] + _fpisLockerBalances[i] + _vestedFXSBalances[i], _ttlCombinedVeFXS[i], HALF_PCT_DELTA, _errorMsg);

            // Print user totals
            console.log("-------------- %s TOTALS --------------", vm.getLabel(_theUser));
            console.log("VestedFXS: %s", _vestedFXSBalances[i].decimalString(18, false));
            console.log("FPISLocker: %s", _fpisLockerBalances[i].decimalString(18, false));
            console.log("L1veFXS: %s", _l1veFXSBalances[i].decimalString(18, false));
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

    function test_boostedFraxtalFarming() public {
        defaultSetup();

        // Warp to a new week
        _warpToAndRollOne(block.timestamp + ONE_WEEK_SECS_U256);

        // Drop a fixed amount of rewards into the farm and sync
        fxs.transfer(address(farm), 10e18);
        farm.sync();

        // Check the farm emission rate
        uint256[] memory _emission = farm.getRewardForDuration();
        console.log("Emission: ", _emission[0]);

        // Users enter the farm with equal amounts of LP for an equal time
        // Alice
        hoax(alice);
        lp.approve(address(farm), 100e18);
        hoax(alice);
        farm.stakeLocked(100e18, 8 * ONE_WEEK_SECS_U256);

        // Bob
        hoax(bob);
        lp.approve(address(farm), 100e18);
        hoax(bob);
        farm.stakeLocked(100e18, 8 * ONE_WEEK_SECS_U256);

        // Claire
        hoax(claire);
        lp.approve(address(farm), 100e18);
        hoax(claire);
        farm.stakeLocked(100e18, 8 * ONE_WEEK_SECS_U256);

        // Warp to a new week
        _warpToAndRollOne(block.timestamp + ONE_WEEK_SECS_U256);

        // Check earnings
        uint256 _fraxPerLP = farm.fraxPerLPToken();
        uint256 _usdPerVeFXS = 1.8e18 / 4; // For visualization purposes here
        console.log("\n============= USER EARNINGS =============");
        // Loop through all of the users
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Fetch values
            uint256 _lockedLiquidity = farm.lockedLiquidityOf(_theUser);
            uint256 _combinedWeight = farm.combinedWeightOf(_theUser);
            uint256 _fraxValueInLP = (_lockedLiquidity * _fraxPerLP) / 1e18;
            uint256 _usdValueOfVeFXS = (veFXSAggregator.balanceOf(_theUser) * _usdPerVeFXS) / 1e18;

            // Print user totals
            console.log("-------------- %s TOTALS --------------", vm.getLabel(_theUser));
            console.log("Locked Liquidity: %s", (_lockedLiquidity).decimalString(18, false));
            console.log("Combined Weight: %s", (_combinedWeight).decimalString(18, false));
            console.log("FRAX Value in the LP: %s", (_fraxValueInLP).decimalString(18, false));
            console.log("Value of veFXS: %s", (_usdValueOfVeFXS).decimalString(18, false));
            console.log("Earnings: %s", (farm.earned(_theUser)[0]).decimalString(18, false));
            console.log("veFXS Multiplier: %sx", (farm.veFXSMultiplier(_theUser)).decimalString(18, false));
        }
    }

    function _warpToAndRollOne(uint256 _newTs) public {
        vm.warp(_newTs);
        vm.roll(block.number + 1);
    }
}
