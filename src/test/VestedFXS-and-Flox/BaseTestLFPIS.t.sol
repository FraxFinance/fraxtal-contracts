// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

import { FraxTest } from "frax-std/FraxTest.sol";
import { DeployFPISLocker } from "src/script/VestedFXS-and-Flox/DeployFPISLocker.s.sol";
import { DeployVestedFXS } from "src/script/VestedFXS-and-Flox/DeployVestedFXS.s.sol";
import { FloxIncentivesDistributor } from "src/contracts/VestedFXS-and-Flox/Flox/FloxIncentivesDistributor.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { FPISLocker } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLocker.sol";
import { FPISLockerUtils } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLockerUtils.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { IlFPISEvents } from "src/contracts/VestedFXS-and-Flox/FPISLocker/IlFPISEvents.sol";
import { IlFPISStructs } from "src/contracts/VestedFXS-and-Flox/FPISLocker/IlFPISStructs.sol";
import { console } from "frax-std/FraxTest.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseTestLFPIS is FraxTest, IlFPISEvents, IlFPISStructs, Constants.Helper {
    // LFPIS-specific
    // =========================================
    MintableBurnableTestERC20 public token;
    MintableBurnableTestERC20 public fxs;
    VestedFXS public vestedFXS;
    FPISLocker public lockedFPIS;
    FPISLockerUtils public lockedFPISUtils;
    FloxIncentivesDistributor public flox;

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
    uint256 public constant MAXTIME_UINT256 = 4 * 365 * 86_400; // 4 years

    // _expectedLFPIS = uint256(uint128(_fxsAmount + ((3 * _fxsAmount *_timeLeft_i128) / MAXTIME)));
    uint128 public LOCK_SECONDS_MAX_ONE_THIRD; // Number of weeks to get a 0,6663x lFPIS multiplier
    uint128 public LOCK_SECONDS_MAX_TWO_THIRDS; // Number of weeks to get a 0.9997x lFPIS multiplier
    uint128 public LOCK_SECONDS_MAX; // Number of weeks to get a 1.333x lFPIS multiplier

    uint256 public HALF_PCT_DELTA = 0.005e18;
    uint256 public ONE_PCT_DELTA = 0.01e18;

    int128 public constant VOTE_WEIGHT_MULTIPLIER = 13_330 - 3330;

    int128 public constant VOTE_BASIS_POINTS = 10_000;

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

    function defaultSetup() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 18_121_304);

        // Set some variables
        // ======================
        LOCK_SECONDS_MAX_ONE_THIRD = (1 * MAXTIME_UINT128) / 3;
        LOCK_SECONDS_MAX_TWO_THIRDS = (2 * MAXTIME_UINT128) / 3;
        LOCK_SECONDS_MAX = MAXTIME_UINT128;

        // Deploy the contracts
        // ======================

        // Deploy the lFPIS contracts
        token = new MintableBurnableTestERC20("mock Locked", "mFPIS");
        fxs = new MintableBurnableTestERC20("mock FXS", "mFXS");
        DeployVestedFXS vestedFXSDeployer = new DeployVestedFXS();
        (vestedFXS,) = vestedFXSDeployer.runTest(address(fxs), "VestedFXS");
        (lockedFPIS, lockedFPISUtils) = (new DeployFPISLocker()).runTest(address(token), address(fxs), address(vestedFXS));

        // Set up the Flox Incentives Distributor
        flox = new FloxIncentivesDistributor(address(lockedFPIS), address(token));

        // Print the admin
        console.log("lockedFPIS admin (in BaseTest): ", lockedFPIS.lockerAdmin());
        console.log("This address (in BaseTest): ", address(this));

        // Set the vestedFXS admin to this contract
        hoax(vestedFXS.admin());
        vestedFXS.commitTransferOwnership(address(this));
        vestedFXS.acceptTransferOwnership();

        // Set the lockedFPIS admin to this contract
        hoax(lockedFPIS.lockerAdmin());
        lockedFPIS.commitTransferOwnership(address(this));
        lockedFPIS.acceptTransferOwnership();

        // Set the FPISLockerUtils on the FPISLocker contract
        lockedFPIS.setLFPISUtils(address(lockedFPISUtils));

        // Set lockedFPIS as Flox contributor of vestedFXS in order to enable lFPIS => veFXS migration
        vestedFXS.setFloxContributor(address(lockedFPIS), true);

        // Set the allowance fo veFXS to spend FXS from lFPIS
        lockedFPIS.updateVeFXSAllowance();

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
    }
}
