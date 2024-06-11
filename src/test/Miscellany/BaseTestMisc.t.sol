// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

import { FraxTest } from "frax-std/FraxTest.sol";
import { DeploySfraxMintRedeemer } from "src/script/Miscellany/DeploySfraxMintRedeemer.s.sol";
import { DeployTimedLocker } from "src/script/Miscellany/DeployTimedLocker.s.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { ManualPriceOracle } from "src/contracts/Miscellany/ManualPriceOracle.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { TimedLocker } from "src/contracts/Miscellany/TimedLocker.sol";
import { console } from "frax-std/FraxTest.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
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
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 19_820_000);

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
