// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

import { FraxTest } from "frax-std/FraxTest.sol";
import { DeployFraxFarmQuitCreditors_UniV3 } from "src/script/Miscellany/DeployFraxFarmQuitCreditors_UniV3.s.sol";
import { DeploySfraxMintRedeemer } from "src/script/Miscellany/DeploySfraxMintRedeemer.s.sol";
import { DeployTimedLocker } from "src/script/Miscellany/DeployTimedLocker.s.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ManualPriceOracle } from "src/contracts/Miscellany/ManualPriceOracle.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FraxFarmQuitCreditor_UniV3 } from "src/contracts/Miscellany/FraxFarmQuitCreditor/FraxFarmQuitCreditor_UniV3.sol";
import { INonfungiblePositionManager, ComboOracle_UniV2_UniV3, IFraxFarmUniV3 } from "src/contracts/Miscellany/FraxFarmQuitCreditor/Imports.sol";
import { TimedLocker } from "src/contracts/Miscellany/TimedLocker.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseTestMisc is FraxTest, Constants.Helper {
    // FraxtalERC4626MintRedeemer
    // =========================================
    MintableBurnableTestERC20 public frax;
    MintableBurnableTestERC20 public sfrax;
    FraxtalERC4626MintRedeemer public sfraxMintRedeemer;
    address public sfxMRAddress;
    ManualPriceOracle public fraxOracle;
    ManualPriceOracle public sfraxOracle;

    // QuitCreditor
    // =========================================
    IERC20Metadata public mainnetFXS;
    INonfungiblePositionManager public univ3NftPositionMgr;
    IFraxFarmUniV3 public fraxFarmUniV3FraxUsdc;
    FraxFarmQuitCreditor_UniV3 public quitCreditorFRAXDAI;
    FraxFarmQuitCreditor_UniV3 public quitCreditorFRAXUSDC;
    IERC20Metadata public qcToken0;
    IERC20Metadata public qcToken1;
    uint256[2] public qcMissingDecimals;

    // // FRAXToFXBLockerRouter
    // // =========================================
    // FRAXToFXBLockerRouter public lockerRouter;

    // TimedLocker
    // =========================================
    MintableBurnableTestERC20 public fxs;
    MintableBurnableTestERC20 public fxb;
    TimedLocker public timedLocker;
    address public timedLockerAddress;

    // Test users
    // =========================================

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
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 20_412_924);

        // FraxtalERC4626MintRedeemer
        // ----------------------------------------------

        // Deploy the token and FraxtalERC4626MintRedeemer contracts
        frax = new MintableBurnableTestERC20("mock FRAX", "mFRAX");
        sfrax = new MintableBurnableTestERC20("mock sFRAX", "msFRAX");
        DeploySfraxMintRedeemer mintRedeemerDeployer = new DeploySfraxMintRedeemer();
        (sfraxMintRedeemer, fraxOracle, sfraxOracle) = mintRedeemerDeployer.runTest(address(frax), address(sfrax));
        sfxMRAddress = address(sfraxMintRedeemer);

        // Set the FraxtalERC4626MintRedeemer admin to this contract
        hoax(sfraxMintRedeemer.owner());
        sfraxMintRedeemer.nominateNewOwner(address(this));
        sfraxMintRedeemer.acceptOwnership();

        // // FRAXToFXBLockerRouter
        // // ----------------------------------------------
        // DeployFRAXToFXBLockerRouter lockerRouterDeployer = new DeployFRAXToFXBLockerRouter();
        // lockerRouter = lockerRouterDeployer.runTest();

        // QuitCreditor FRAX/USDC
        // ----------------------------------------------
        mainnetFXS = IERC20Metadata(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
        univ3NftPositionMgr = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        fraxFarmUniV3FraxUsdc = IFraxFarmUniV3(0x3EF26504dbc8Dd7B7aa3E97Bc9f3813a9FC0B4B0);
        DeployFraxFarmQuitCreditors_UniV3 quitCreditorDeployers = new DeployFraxFarmQuitCreditors_UniV3();
        (quitCreditorFRAXDAI, quitCreditorFRAXUSDC) = quitCreditorDeployers.runTest();

        // Just do FRAX/USDC for the tests
        qcToken0 = IERC20Metadata(fraxFarmUniV3FraxUsdc.uni_token0());
        qcToken1 = IERC20Metadata(fraxFarmUniV3FraxUsdc.uni_token1());
        qcMissingDecimals[0] = quitCreditorFRAXUSDC.missingDecimals(0);
        qcMissingDecimals[1] = quitCreditorFRAXUSDC.missingDecimals(1);

        // Make the QuitCreditor-related addresses persistent
        vm.makePersistent(address(univ3NftPositionMgr), address(fraxFarmUniV3FraxUsdc));
        vm.makePersistent(address(quitCreditorFRAXDAI), address(quitCreditorFRAXUSDC));

        // TimedLocker
        // ----------------------------------------------

        // Deploy the token and TimedLocker contracts
        fxs = new MintableBurnableTestERC20("mock FXS", "mFXS");
        fxb = new MintableBurnableTestERC20("mock FXB", "mFXB");
        DeployTimedLocker timedLockerDeployer = new DeployTimedLocker();
        timedLocker = timedLockerDeployer.runTest(address(fxb), address(fxs));
        timedLockerAddress = address(timedLocker);

        // Set the TimedLocker admin to this contract
        hoax(timedLocker.owner());
        timedLocker.nominateNewOwner(address(this));
        timedLocker.acceptOwnership();

        // Labels
        // ----------------------------------------------
        vm.label(address(fraxOracle), "fraxOracle");
        vm.label(address(sfraxOracle), "sfraxOracle");
        vm.label(address(frax), "mFRAX");
        vm.label(address(sfrax), "msFRAX");
        vm.label(address(fxs), "mFXS");
        vm.label(address(fxb), "mFXB");

        // Test users
        // ----------------------------------------------

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

    function _warpToAndRollOne(uint256 _newTs) public {
        vm.warp(_newTs);
        vm.roll(block.number + 1);
    }
}
