// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

import { FraxTest } from "frax-std/FraxTest.sol";
import { DeployFPISLocker } from "src/script/VestedFXS-and-Flox/DeployFPISLocker.s.sol";
import { DeployL1VeFXS } from "src/script/VestedFXS-and-Flox/DeployL1VeFXS.s.sol";
import { DeployL1VeFXSTotalSupplyOracle } from "src/script/VestedFXS-and-Flox/DeployL1VeFXSTotalSupplyOracle.s.sol";
import { DeployYieldDistributor } from "src/script/VestedFXS-and-Flox/DeployYieldDistributor.s.sol";
import { DeployVeFXSAggregator } from "src/script/VestedFXS-and-Flox/DeployVeFXSAggregator.s.sol";
import { DeployVestedFXS } from "src/script/VestedFXS-and-Flox/DeployVestedFXS.s.sol";
import { DeployFloxCapacitor } from "src/script/VestedFXS-and-Flox/DeployFloxCapacitor.s.sol";
import { DeployFloxConverter } from "src/script/VestedFXS-and-Flox/DeployFloxConverter.s.sol";
import { DeployFraxStaker } from "src/script/VestedFXS-and-Flox/DeployFraxStaker.s.sol";
import { FloxIncentivesDistributor } from "src/contracts/VestedFXS-and-Flox/Flox/FloxIncentivesDistributor.sol";
import { FloxCapacitor } from "src/contracts/VestedFXS-and-Flox/Flox/FloxCapacitor.sol";
import { FloxConverter } from "src/contracts/VestedFXS-and-Flox/Flox/FloxConverter.sol";
import { L1VeFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXS.sol";
import { L1VeFXSTotalSupplyOracle } from "src/contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXSTotalSupplyOracle.sol";
import { FPISLocker } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLocker.sol";
import { FPISLockerUtils } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLockerUtils.sol";
import { FraxStaker } from "src/contracts/VestedFXS-and-Flox/FraxStaker/FraxStaker.sol";
import { YieldDistributor } from "src/contracts/VestedFXS-and-Flox/VestedFXS/YieldDistributor.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { IveFXSEvents } from "src/contracts/VestedFXS-and-Flox/VestedFXS/IveFXSEvents.sol";
import { IveFXSStructs } from "src/contracts/VestedFXS-and-Flox/VestedFXS/IveFXSStructs.sol";
import { console } from "frax-std/FraxTest.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";

contract BaseTestVeFXS is FraxTest, IveFXSEvents, IveFXSStructs, Constants.Helper {
    // VeFXS-specific
    // =========================================
    MintableBurnableTestERC20 public token;
    VestedFXS public vestedFXS;
    VestedFXSUtils public vestedFXSUtils;
    FloxIncentivesDistributor public flox;
    VeFXSAggregator public veFXSAggregator;
    YieldDistributor public yieldDistributor;
    VestedFXS public addlVeFXS;
    VestedFXSUtils public addlVestedFXSUtils;

    // FPISLocker-specific
    // =========================================
    MintableBurnableTestERC20 public tokenFPIS;
    FPISLocker public fpisLocker;
    FPISLockerUtils public fpisLockerUtils;

    // L1VeFXS
    // =========================================
    L1VeFXS public l1VeFXS;
    L1VeFXSTotalSupplyOracle public l1VeFXSTotalSupplyOracle;

    // FloxCapacitpr
    // =========================================
    FloxCapacitor public floxCap;

    // FraxStaker
    // =========================================
    FraxStaker public fraxStaker;

    // FloxConverter
    // =========================================
    FloxConverter public floxConverter;

    // Misc
    // =========================================

    uint128 public constant DEPOSIT_FOR_TYPE = 0;
    uint128 public constant CREATE_LOCK_TYPE = 1;
    uint128 public constant INCREASE_LOCK_AMOUNT = 2;
    uint128 public constant INCREASE_UNLOCK_TIME = 3;

    uint256 constant DAY = 86_400;
    int128 public constant WEEK = 7 * 86_400; // all future times are rounded by week
    uint256 public constant WEEK_UINT256 = 7 * 86_400; // all future times are rounded by week
    uint128 public constant WEEK_UINT128 = 7 * 86_400; // 7 days
    int128 public constant MAXTIME = 4 * 365 * 86_400; // 4 years
    uint128 public constant MAXTIME_UINT128 = 4 * 365 * 86_400; // 4 years

    // _expectedVeFXS = uint256(uint128(_fxsAmount + ((3 * _fxsAmount *_timeLeft_i128) / MAXTIME)));
    uint128 public LOCK_SECONDS_2X; // Number of weeks to get a 2x veFXS multiplier
    uint128 public LOCK_SECONDS_3X; // Number of weeks to get a 3x veFXS multiplier
    uint128 public LOCK_SECONDS_4X; // Number of weeks to get a 4x veFXS multiplier

    uint256 public HALF_PCT_DELTA = 0.005e18;
    uint256 public ONE_PCT_DELTA = 0.01e18;

    int128 public constant VOTE_WEIGHT_MULTIPLIER = 4 - 1;

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
    uint256 public whalePrivateKey;
    address payable public whale;

    function defaultSetup() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 18_121_304);

        // Set some variables
        // ======================
        LOCK_SECONDS_2X = (1 * MAXTIME_UINT128) / 3;
        LOCK_SECONDS_3X = (2 * MAXTIME_UINT128) / 3;
        LOCK_SECONDS_4X = MAXTIME_UINT128;

        // Deploy the contracts
        // ======================

        // Deploy the veFXS contracts
        token = new MintableBurnableTestERC20("mock Vested", "mFXS");
        (vestedFXS, vestedFXSUtils) = (new DeployVestedFXS()).runTest(address(token), "VestedFXS");
        vm.label(address(vestedFXS), "VestedFXSPxy");
        vm.label(address(vestedFXSUtils), "VestedFXSUtilsPxy");

        // Deploy the FPISLocker contracts
        tokenFPIS = new MintableBurnableTestERC20("mock Locked FPIS", "mFPIS");
        (fpisLocker, fpisLockerUtils) = (new DeployFPISLocker()).runTest(address(tokenFPIS), address(token), address(vestedFXS));
        vm.label(address(fpisLocker), "FPISLockerPxy");
        vm.label(address(fpisLocker), "FPISLockerUtils");

        // Deploy the L1VeFXS contracts
        l1VeFXS = (new DeployL1VeFXS()).runTest();
        l1VeFXSTotalSupplyOracle = (new DeployL1VeFXSTotalSupplyOracle()).runTest();
        vm.label(address(l1VeFXS), "L1VeFXS");
        vm.label(address(l1VeFXSTotalSupplyOracle), "L1VeFXSTotalSupplyOracle");

        // Deploy the additional veFXS contracts
        (addlVeFXS, addlVestedFXSUtils) = (new DeployVestedFXS()).runTest(address(token), "AddlVeFXS");
        vm.label(address(addlVeFXS), "AddlVestedFXSPxy");
        vm.label(address(addlVestedFXSUtils), "AddlVestedFXSUtilsPxy");

        // Deploy the veFXS Aggregator contract
        address[6] memory _veAddresses = [address(vestedFXS), address(vestedFXSUtils), address(fpisLocker), address(fpisLockerUtils), address(l1VeFXS), address(l1VeFXSTotalSupplyOracle)];
        veFXSAggregator = (new DeployVeFXSAggregator()).runTest(_veAddresses);
        vm.label(address(veFXSAggregator), "VeFXSAggregator");

        // Deploy the veFXS contracts
        yieldDistributor = (new DeployYieldDistributor()).runTest(address(token), address(veFXSAggregator));
        vm.label(address(yieldDistributor), "VeFXSYldDistPxy");

        // Deploy the FraxStaker
        fraxStaker = (new DeployFraxStaker()).runTest(address(this), "FraxStaker");
        vm.label(address(fraxStaker), "FraxStaker");

        // Deploy the FloxCapacitor
        floxCap = (new DeployFloxCapacitor()).runTest(address(fraxStaker), address(this), address(veFXSAggregator), "FloxCAP");
        vm.label(address(floxCap), "FloxCAP");

        // Deploy the FloxConverter
        floxConverter = (new DeployFloxConverter()).runTest(address(floxCap), address(this), address(token), "FloxConverter");
        vm.label(address(floxConverter), "FloxConverter");

        // Set up the Flox Incentives Distributor
        flox = new FloxIncentivesDistributor(address(vestedFXS), address(token));
        vm.label(address(flox), "FloxIncentivesDistributor");

        // Print the admin
        console.log("vestedFXS admin (in BaseTest): ", vestedFXS.admin());
        console.log("This address (in BaseTest): ", address(this));

        // Set the vestedFXS admin to this contract
        hoax(vestedFXS.admin());
        vestedFXS.commitTransferOwnership(address(this));
        vestedFXS.acceptTransferOwnership();

        // // Set the L1veFXS owner to this contract
        // hoax(l1VeFXS.owner());
        // l1VeFXS.transferOwnership(address(this));
        // l1VeFXS.acceptOwnership();

        // // Set the L1VeFXSTotalSupplyOracle owner to this contract
        // hoax(l1VeFXSTotalSupplyOracle.owner());
        // l1VeFXSTotalSupplyOracle.nominateNewOwner(address(this));
        // l1VeFXSTotalSupplyOracle.acceptOwnership();

        // Set the LockedFPIS admin to this contract
        hoax(fpisLocker.lockerAdmin());
        fpisLocker.commitTransferOwnership(address(this));
        fpisLocker.acceptTransferOwnership();

        // Set the VeFXSAggregator owner to this contract
        hoax(veFXSAggregator.owner());
        veFXSAggregator.nominateNewOwner(address(this));
        veFXSAggregator.acceptOwnership();

        // Set the YieldDistributor owner to this contract
        hoax(yieldDistributor.owner());
        yieldDistributor.nominateNewOwner(address(this));
        yieldDistributor.acceptOwnership();

        // Add the Additional VeFXS contract to the VeFXS Aggregator
        veFXSAggregator.addAddlVeFXSContract(address(addlVeFXS));

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

        // Set up Whale
        whalePrivateKey = 0x1337133713371337;
        whale = payable(vm.addr(whalePrivateKey));
        vm.label(whale, "Whale");
    }

    function _warpToAndRollOne(uint256 _newTs) public {
        vm.warp(_newTs);
        vm.roll(block.number + 1);
    }
}
