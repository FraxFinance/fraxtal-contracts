// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import { console } from "frax-std/FraxTest.sol";
import { DecimalStringHelper } from "../helpers/DecimalStringHelper.sol";
import { DoubleOptInVeFXSDelegation } from "src/contracts/VestedFXS-and-Flox/VestedFXS/DoubleOptInVeFXSDelegation.sol";
import { FPISLocker } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLocker.sol";
import { ICrossDomainMessenger } from "src/contracts/Miscellany/FraxFarmQuitCreditor/ICrossDomainMessenger.sol";
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

contract Misc_Test_DoubleOptInVeFXSDelegation is FraxTest, IveFXSEvents, IveFXSStructs {
    using stdStorage for StdStorage;
    using DecimalStringHelper for uint256;

    // Avoid stack-too-deep
    address[3] public _userAddrs;
    address[8] public _userAddrsExtd;

    uint256 public _testStartTimestamp;
    mapping(address user => mapping(address lockLocation => uint128[] lockIndices)) _expiringLocks;

    // ERC20s
    // =========================================
    MintableERC20 public fxs = MintableERC20(Constants.FraxtalMainnet.FXS_ERC20);

    // veFXS
    // =========================================
    FPISLocker public fpisLocker = FPISLocker(Constants.FraxtalMainnet.FPIS_LOCKER_PROXY);
    L1VeFXS public l1VeFXS = L1VeFXS(Constants.FraxtalMainnet.L1VEFXS_PROXY);
    VestedFXS public vestedFXS = VestedFXS(Constants.FraxtalMainnet.VESTED_FXS_PROXY);
    VeFXSAggregator public veFXSAggregator = VeFXSAggregator(Constants.FraxtalMainnet.VEFXS_AGGREGATOR_PROXY);
    YieldDistributor public yieldDistributor = YieldDistributor(Constants.FraxtalMainnet.YIELD_DISTRIBUTOR_PROXY);
    DoubleOptInVeFXSDelegation public veFXSDelegation;
    uint256 public _minGasLimit;

    // Misc
    // =========================================
    ICrossDomainMessenger public messenger = ICrossDomainMessenger(0x4200000000000000000000000000000000000007);

    uint256 public alicePrivateKey;
    address payable public alice;
    uint256 public bobPrivateKey;
    address payable public bob;
    uint256 public clairePrivateKey;
    address payable public claire;
    uint256 public davePrivateKey;
    address payable public dave;
    uint256 public ericPrivateKey;
    address payable public eric;
    uint256 public frankPrivateKey;
    address payable public frank;
    uint256 public geraldPrivateKey;
    address payable public gerald;
    uint256 public harryPrivateKey;
    address payable public harry;

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
        vm.createSelectFork(vm.envString("FRAXTAL_RPC_URL"), 9_250_997);

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

        // Set up Dave
        davePrivateKey = 0xDa;
        dave = payable(vm.addr(davePrivateKey));
        vm.label(dave, "Dave");

        // Set up Eric
        ericPrivateKey = 0xe0;
        eric = payable(vm.addr(ericPrivateKey));
        vm.label(eric, "Eric");

        // Set up Frank
        frankPrivateKey = 0xf0;
        frank = payable(vm.addr(frankPrivateKey));
        vm.label(frank, "Frank");

        // Set up Gerald
        geraldPrivateKey = 0x6e2a1d;
        gerald = payable(vm.addr(geraldPrivateKey));
        vm.label(gerald, "Gerald");

        // Set up Harry
        harryPrivateKey = 0x4a229;
        harry = payable(vm.addr(harryPrivateKey));
        vm.label(harry, "Harry");

        // Tracking
        _userAddrs = [alice, bob, claire];
        _userAddrsExtd = [alice, bob, claire, dave, eric, frank, gerald, harry];

        // Instantiate the DoubleOptInVeFXSDelegation
        veFXSDelegation = new DoubleOptInVeFXSDelegation();

        // Labels
        vm.label(address(fxs), "fxs");
        vm.label(address(fpisLocker), "fpisLocker");
        vm.label(address(l1VeFXS), "l1VeFXS");
        vm.label(address(vestedFXS), "vestedFXS");
        vm.label(address(veFXSAggregator), "veFXSAggregator");
        vm.label(address(veFXSDelegation), "veFXSDelegation");

        // Give users some FXS
        vm.startPrank(Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG);
        fxs.transfer(address(this), 10_000e18);
        fxs.transfer(alice, 10_000e18);
        fxs.transfer(bob, 10_000e18);
        fxs.transfer(claire, 10_000e18);
        fxs.transfer(frank, 1000e18);
        vm.stopPrank();

        // Warp to the start of an epoch week
        _testStartTimestamp = 604_800 * (1 + (block.timestamp / 604_800));
        _warpToAndRollOne(_testStartTimestamp);

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

        // Frank
        // veFXS should be 50 * 2 = 100
        hoax(frank);
        fxs.approve(address(vestedFXS), 50e18);
        hoax(frank);
        (_tmpLockindex,) = vestedFXS.createLock(frank, 50e18, uint128(block.timestamp) + LOCK_SECONDS_2X_U64);
        _expiringLocks[frank][address(vestedFXS)].push(_tmpLockindex);

        assertApproxEqRel(vestedFXS.balanceOf(frank), 100e18, HALF_PCT_DELTA, "vestedFXS.balanceOf(frank) should be 100");

        // Check aggregate balances
        // ===============================================
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(alice), 200e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(alice) should be 200");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(bob), 600e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(bob) should be 600");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(claire), 10_000e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(claire) should be 10000");
        assertApproxEqRel(veFXSAggregator.ttlCombinedVeFXS(frank), 100e18, HALF_PCT_DELTA, "veFXSAggregator.ttlCombinedVeFXS(frank) should be 100");

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

    function printDelegatedActiveLocks() public {
        // Print
        console.log(unicode"\n🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳 DELEGATED ACTIVE LOCKS 🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳");

        for (uint256 j = 0; j < _userAddrsExtd.length; j++) {
            // Get the user
            address _theUser = _userAddrsExtd[j];

            // Print
            console.log(unicode"🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱 %s 🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱", vm.getLabel(_theUser));

            // Fetch the active locks for the user
            LockedBalanceExtendedV2[] memory _activeLocks = veFXSDelegation.getAllCurrActiveLocks(_theUser, true);

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

    function printDelegatedExpiredLocks() public {
        // Print
        console.log(unicode"\n🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦 DELEGATED EXPIRED LOCKS 🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦🪦");

        for (uint256 j = 0; j < _userAddrsExtd.length; j++) {
            // Get the user
            address _theUser = _userAddrsExtd[j];

            // Print
            console.log(unicode"💀💀💀💀💀💀💀💀 %s 💀💀💀💀💀💀💀💀", vm.getLabel(_theUser));

            // Fetch the expired locks for the user
            LockedBalanceExtendedV2[] memory _expiredLocks = veFXSDelegation.getAllExpiredLocks(_theUser);

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

    function test_doubleOptInVeFXSDelegation() public {
        defaultSetup();

        // Check initial delegations
        // --------------------------
        console.log("");

        // Loop through all of the users
        for (uint256 i = 0; i < _userAddrs.length; i++) {
            // Get the user
            address _theUser = _userAddrs[i];

            // Print
            console.log(unicode"⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐ Initial Delegations for %s ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐", vm.getLabel(_theUser));

            // Get the balances
            uint256 _aggVeFXS = veFXSAggregator.ttlCombinedVeFXS(_theUser);
            uint256 _delegVeFXS = veFXSDelegation.balanceOf(_theUser);

            // Print
            console.log("Raw (aggregator) veFXS: %s", _aggVeFXS.decimalString(18, false));
            console.log("Delegated veFXS: %s", _delegVeFXS.decimalString(18, false));

            // Check aggregate balances
            // ===============================================
            assertEq(_aggVeFXS, _delegVeFXS, "Delegated and raw veFXS should be the same");
        }

        // Perform initial delegations
        // --------------------------

        // Alice delegates to Dave
        hoax(alice);
        veFXSDelegation.nominateDelegatee(dave);

        // Dave accepts Alice's delegation
        hoax(dave);
        veFXSDelegation.acceptDelegation(alice);

        // Bob doesn't delegate
        // Do nothing

        // Claire delegates to Eric via Cross-Chain messaging
        {
            // Get the current nonce
            uint256 _currNonce = messenger.messageNonce();

            // Prepare simulating Ethereum Mainnet Claire cross-chain nominating Eric
            bytes memory _encodedNominationMessage = abi.encodeCall(DoubleOptInVeFXSDelegation.nominateDelegateeCrossChain, (eric));

            // Fetch the _minGasLimit
            _minGasLimit = 500_000;

            // Impersonate the relayMessage caller and relay the messages to the VeFXSDelegation contract
            hoax(0x237cCc31Bc076b3D515F60fBC81Fdde0b0D553fE);
            messenger.relayMessage(_currNonce, claire, address(veFXSDelegation), 0, _minGasLimit, _encodedNominationMessage);
        }

        // Claire changes her mind and delegates to Frank
        hoax(claire);
        veFXSDelegation.nominateDelegatee(frank);

        // Eric cannot accept Claire's nomination
        vm.expectRevert(DoubleOptInVeFXSDelegation.SenderNotNominee.selector);
        hoax(eric);
        veFXSDelegation.acceptDelegation(claire);

        // Frank accepts Claire's delegation
        hoax(frank);
        veFXSDelegation.acceptDelegation(claire);

        // Check delegations again
        // --------------------------
        console.log("");

        // Check specific relationships
        // Delegatees
        assertEq(veFXSDelegation.delegateeFor(alice), dave, "alice delegateeFor check #1");
        assertEq(veFXSDelegation.delegateeFor(bob), address(0), "bob delegateeFor check #1");
        assertEq(veFXSDelegation.delegateeFor(claire), frank, "claire delegateeFor check #1");
        assertEq(veFXSDelegation.delegateeFor(dave), address(0), "dave delegateeFor check #1");
        assertEq(veFXSDelegation.delegateeFor(eric), address(0), "eric delegateeFor check #1");
        assertEq(veFXSDelegation.delegateeFor(frank), address(0), "frank delegateeFor check #1");
        assertEq(veFXSDelegation.delegateeFor(gerald), address(0), "gerald delegateeFor check #1");
        assertEq(veFXSDelegation.delegateeFor(harry), address(0), "harry delegateeFor check #1");

        // Delegators
        assertEq(veFXSDelegation.delegatorFor(alice), address(0), "alice delegatorFor check #1");
        assertEq(veFXSDelegation.delegatorFor(bob), address(0), "bob delegatorFor check #1");
        assertEq(veFXSDelegation.delegatorFor(claire), address(0), "claire delegatorFor check #1");
        assertEq(veFXSDelegation.delegatorFor(dave), alice, "dave delegatorFor check #1");
        assertEq(veFXSDelegation.delegatorFor(eric), address(0), "eric delegatorFor check #1");
        assertEq(veFXSDelegation.delegatorFor(frank), claire, "frank delegatorFor check #1");
        assertEq(veFXSDelegation.delegatorFor(gerald), address(0), "gerald delegatorFor check #1");
        assertEq(veFXSDelegation.delegatorFor(harry), address(0), "harry delegatorFor check #1");

        // Loop through all of the users
        for (uint256 i = 0; i < _userAddrsExtd.length; i++) {
            // Get the user
            address _theUser = _userAddrsExtd[i];

            // Print
            console.log(unicode"➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️  Middle Delegations for %s ➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️", vm.getLabel(_theUser));

            // Get the balances
            uint256 _aggVeFXS = veFXSAggregator.ttlCombinedVeFXS(_theUser);
            uint256 _delegVeFXS = veFXSDelegation.ttlCombinedVeFXS(_theUser);
            (uint256 _addressType, address _delegator, address _delegatee) = veFXSDelegation.delegationInfo(_theUser);

            // Get the address type string
            string memory _addrTypeStr;
            if (_addressType == 0) _addrTypeStr = "(0) Undelegated";
            else if (_addressType == 1) _addrTypeStr = "(1) Delegator";
            else _addrTypeStr = "(2) Delegatee";

            // Print
            console.log("Raw (aggregator) veFXS: %s", _aggVeFXS.decimalString(18, false));
            console.log("Delegated veFXS: %s", _delegVeFXS.decimalString(18, false));
            console.log("_addressType: %s", _addrTypeStr);
            console.log("_delegator: %s", vm.getLabel(_delegator));
            console.log("_delegatee: %s", vm.getLabel(_delegatee));

            // Specific user checks
            if (_theUser == alice) {
                assertApproxEqRel(_delegVeFXS, 0, HALF_PCT_DELTA, "Alice's delegated balance should be 0");
            } else if (_theUser == bob) {
                assertApproxEqRel(_delegVeFXS, _aggVeFXS, HALF_PCT_DELTA, "Bob is undelegated so raw should match delegated");
            } else if (_theUser == claire) {
                assertApproxEqRel(_delegVeFXS, 0, HALF_PCT_DELTA, "Claire's delegated balance should be 0");
            } else if (_theUser == dave) {
                assertApproxEqRel(_delegVeFXS, veFXSAggregator.ttlCombinedVeFXS(alice), HALF_PCT_DELTA, "Dave's delegated balance should match Alice's");
            } else if (_theUser == eric) {
                assertApproxEqRel(_aggVeFXS, 0, HALF_PCT_DELTA, "Eric should have 0 raw veFXS");
                assertApproxEqRel(_delegVeFXS, 0, HALF_PCT_DELTA, "Eric should have 0 delegated veFXS");
            } else if (_theUser == frank) {
                assertApproxEqRel(_delegVeFXS, _aggVeFXS + veFXSAggregator.ttlCombinedVeFXS(claire), HALF_PCT_DELTA, "Frank's balance should be his + Claire's");
            } else if (_theUser == gerald) {
                assertApproxEqRel(_aggVeFXS, 0, HALF_PCT_DELTA, "Gerald should have 0 raw veFXS");
                assertApproxEqRel(_delegVeFXS, 0, HALF_PCT_DELTA, "Gerald should have 0 delegated veFXS");
            }
        }
        // Print user active locks
        printActiveLocks();
        printDelegatedActiveLocks();

        // Print user expired locks
        printExpiredLocks();
        printDelegatedExpiredLocks();

        // Bob nominates Frank
        hoax(bob);
        veFXSDelegation.nominateDelegatee(frank);

        // Frank tried to accept, but it fails because Frank is already delegating for Claire
        vm.expectRevert(DoubleOptInVeFXSDelegation.NomineeAlreadyADelegatee.selector);
        hoax(frank);
        veFXSDelegation.acceptDelegation(bob);

        // Alice nominates Eric
        hoax(alice);
        veFXSDelegation.nominateDelegatee(eric);

        // Eric tries to become Alice's delegatee, but it fails because Alice is already a delegator. She needs to rescind first.
        vm.expectRevert(DoubleOptInVeFXSDelegation.DelegatorAlreadyADelegator.selector);
        hoax(eric);
        veFXSDelegation.acceptDelegation(alice);

        // Frank nominates Eric
        hoax(frank);
        veFXSDelegation.nominateDelegatee(eric);

        // Eric tries to become Frank's nominee, but it fails because Frank is already a delegatee
        vm.expectRevert(DoubleOptInVeFXSDelegation.DelegatorAlreadyADelegatee.selector);
        hoax(eric);
        veFXSDelegation.acceptDelegation(frank);

        // Frank rescinds being a delegatee
        hoax(frank);
        veFXSDelegation.rescindDelegationAsDelegatee();

        // Frank nominates himself
        hoax(frank);
        veFXSDelegation.nominateDelegatee(frank);

        // Frank tries to accept his own nomination, but fails
        vm.expectRevert(DoubleOptInVeFXSDelegation.CannotDelegateToSelf.selector);
        hoax(frank);
        veFXSDelegation.acceptDelegation(frank);

        // Both Bob and Gerald nominate Frank
        hoax(bob);
        veFXSDelegation.nominateDelegatee(frank);
        hoax(gerald);
        veFXSDelegation.nominateDelegatee(frank);

        // Frank chooses Bob as his delegator
        hoax(frank);
        veFXSDelegation.acceptDelegation(bob);

        // Frank should not be able to switch to Gerald without rescinding first
        vm.expectRevert(DoubleOptInVeFXSDelegation.NomineeAlreadyADelegatee.selector);
        hoax(frank);
        veFXSDelegation.acceptDelegation(gerald);

        // Harry nominates Alice
        hoax(harry);
        veFXSDelegation.nominateDelegatee(alice);

        // Alice cannot accept the nomination because she needs to rescind first
        vm.expectRevert(DoubleOptInVeFXSDelegation.NomineeAlreadyADelegator.selector);
        hoax(alice);
        veFXSDelegation.acceptDelegation(harry);

        // Bob rescinds being a delegator via Cross-Chain messaging
        {
            // Get the current nonce
            uint256 _currNonce = messenger.messageNonce();

            // Prepare simulating Ethereum Mainnet Claire cross-chain nominating Eric
            bytes memory _encodedRecissionMessage = abi.encodeCall(DoubleOptInVeFXSDelegation.rescindDelegationAsDelegatorCrossChain, ());

            // Fetch the _minGasLimit
            _minGasLimit = 500_000;

            // Impersonate the relayMessage caller and relay the messages to the VeFXSDelegation contract
            hoax(0x237cCc31Bc076b3D515F60fBC81Fdde0b0D553fE);
            messenger.relayMessage(_currNonce, bob, address(veFXSDelegation), 0, _minGasLimit, _encodedRecissionMessage);
        }

        // Frank should be able to switch to Gerald now
        hoax(frank);
        veFXSDelegation.acceptDelegation(gerald);

        // Gerald rescinds being a delegator
        hoax(gerald);
        veFXSDelegation.rescindDelegationAsDelegator();

        // Check specific relationships
        // Delegatees
        assertEq(veFXSDelegation.delegateeFor(alice), dave, "alice delegateeFor check #2");
        assertEq(veFXSDelegation.delegateeFor(bob), address(0), "bob delegateeFor check #2");
        assertEq(veFXSDelegation.delegateeFor(claire), address(0), "claire delegateeFor check #2");
        assertEq(veFXSDelegation.delegateeFor(dave), address(0), "dave delegateeFor check #2");
        assertEq(veFXSDelegation.delegateeFor(eric), address(0), "eric delegateeFor check #2");
        assertEq(veFXSDelegation.delegateeFor(frank), address(0), "frank delegateeFor check #2");
        assertEq(veFXSDelegation.delegateeFor(gerald), address(0), "gerald delegateeFor check #2");
        assertEq(veFXSDelegation.delegateeFor(harry), address(0), "harry delegateeFor check #2");

        // Delegators
        assertEq(veFXSDelegation.delegatorFor(alice), address(0), "alice delegatorFor check #2");
        assertEq(veFXSDelegation.delegatorFor(bob), address(0), "bob delegatorFor check #2");
        assertEq(veFXSDelegation.delegatorFor(claire), address(0), "claire delegatorFor check #2");
        assertEq(veFXSDelegation.delegatorFor(dave), alice, "dave delegatorFor check #2");
        assertEq(veFXSDelegation.delegatorFor(eric), address(0), "eric delegatorFor check #2");
        assertEq(veFXSDelegation.delegatorFor(frank), address(0), "frank delegatorFor check #2");
        assertEq(veFXSDelegation.delegatorFor(gerald), address(0), "gerald delegatorFor check #2");
        assertEq(veFXSDelegation.delegatorFor(harry), address(0), "harry delegatorFor check #2");
    }

    function _warpToAndRollOne(uint256 _newTs) public {
        vm.warp(_newTs);
        vm.roll(block.number + 1);
    }
}
