// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { FraxTest } from "frax-std/FraxTest.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { OwnedV2AutoMsgSender } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol";
import { ManualPriceOracle } from "src/contracts/Miscellany/ManualPriceOracle.sol";
import { UpgradeSfraxMintRedeemer } from "src/script/Miscellany/UpgradeSfraxMintRedeemer.s.sol";
import { Proxy } from "src/script/Miscellany/Proxy.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";
import { Math } from "@openzeppelin-4/contracts/utils/math/Math.sol";
import "src/Constants.sol" as Constants;

contract Unit_Test_UpgradesFRAXRedeemer is FraxTest, Constants.Helper {
    // FraxtalERC4626MintRedeemer
    // =========================================
    MintableBurnableTestERC20 public frax;
    MintableBurnableTestERC20 public sfrax;
    FraxtalERC4626MintRedeemer public sfraxMintRedeemer;
    address public sfxMRAddress;
    ManualPriceOracle public fraxOracle;
    ManualPriceOracle public sfraxOracle;

    // Test users
    // =========================================

    uint256 public alicePrivateKey;
    address payable public alice;
    uint256 public bobPrivateKey;
    address payable public bob;

    function setup() public {
        vm.createSelectFork(vm.envString("FRAXTAL_RPC_URL"), 15_035_727);

        // FraxtalERC4626MintRedeemer
        // ----------------------------------------------

        // Initialize from existing contracts
        frax = MintableBurnableTestERC20(Constants.FraxtalStandardProxies.FRAX_PROXY);
        sfrax = MintableBurnableTestERC20(Constants.FraxtalStandardProxies.SFRAX_PROXY);
        sfraxMintRedeemer = FraxtalERC4626MintRedeemer(0xBFc4D34Db83553725eC6c768da71D2D9c1456B55);
        sfxMRAddress = address(sfraxMintRedeemer);

        // Set the FraxtalERC4626MintRedeemer admin to this contract
        hoax(sfraxMintRedeemer.owner());
        sfraxMintRedeemer.nominateNewOwner(address(this));
        sfraxMintRedeemer.acceptOwnership();

        // Labels
        // ----------------------------------------------
        vm.label(address(frax), "FRAX");
        vm.label(address(sfrax), "sFRAX");

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
    }

    function test_upgradeMintRedeemer() public {
        setup();

        // Show values before upgrade
        console.log("================ BEFORE UPGRADE ================");
        _previewDepositMintWithdrawRedeem(100_000 wei);

        // Deploy the impl
        UpgradeSfraxMintRedeemer mintRedeemerUpgrader = new UpgradeSfraxMintRedeemer();
        // FraxtalERC4626MintRedeemer _implementation = mintRedeemerUpgrader.runTest(address(frax), address(sfrax), address(sfraxMintRedeemer.priceFeedUnderlying()), address(sfraxMintRedeemer.priceFeedVault()), sfraxMintRedeemer.owner(), sfraxMintRedeemer.fee(), sfraxMintRedeemer.vaultTknPrice());
        FraxtalERC4626MintRedeemer _implementation = mintRedeemerUpgrader.runTest(address(0), address(0), address(0), address(0), address(0), 0, 0);
        // FraxtalERC4626MintRedeemer _implementation = FraxtalERC4626MintRedeemer(0xc13d8E8668f5b54d492f5c3E37cf772206f7D0A6);
        Proxy _mrPxy = Proxy(payable(address(sfraxMintRedeemer)));

        // Fetch the proxy admin (needs to be called by current admin or address(0))
        hoax(address(0));
        address _currPxyAdmin = _mrPxy.admin();

        // Upgrade
        hoax(_currPxyAdmin);
        _mrPxy.upgradeTo(address(_implementation));

        // Show values after upgrade
        console.log("================ AFTER UPGRADE ================");
        _previewDepositMintWithdrawRedeem(1 wei);
    }

    function _previewDepositMintWithdrawRedeem(uint256 _maxErrorAbs) internal returns (uint256 _sharesOutPreview, uint256 _assetsInPreview, uint256 _sharesInPreview, uint256 _assetsOutPreview) {
        // Do Deposit -> Mint first
        console.log("\n----- Common Info -----");
        console.log("getLatestUnderlyingPriceE18: ", sfraxMintRedeemer.getLatestUnderlyingPriceE18());
        console.log("getVaultTknPriceStoredE18: ", sfraxMintRedeemer.getVaultTknPriceStoredE18());

        // Do Deposit -> Mint first
        console.log("\n----- Deposit / Mint -----");

        // preview Deposit
        _sharesOutPreview = sfraxMintRedeemer.previewDeposit(1e18);
        console.log("previewDeposit _sharesOutPreview: ", _sharesOutPreview);

        // previewMint using previewDeposit result
        _assetsInPreview = sfraxMintRedeemer.previewMint(_sharesOutPreview);
        console.log("previewMint _assetsInPreview: ", _assetsInPreview);

        // Check
        assertApproxEqRel(_assetsInPreview, 1e18, _maxErrorAbs, "Deposit / Mint reciprocal amounts mismatch");

        // Now do Withdraw / Redeem
        console.log("\n----- Withdraw / Redeem -----");

        // preview Withdraw
        _sharesInPreview = sfraxMintRedeemer.previewWithdraw(1e18);
        console.log("previewWithdraw _sharesInPreview: ", _sharesInPreview);

        // preview Redeem
        _assetsOutPreview = sfraxMintRedeemer.previewRedeem(_sharesInPreview);
        console.log("previewRedeem _assetsOutPreview: ", _assetsOutPreview);

        // Check. Can be off by _maxErrorAbs
        assertApproxEqRel(_assetsOutPreview, 1e18, _maxErrorAbs, "Withdraw / Redeem reciprocal amounts mismatch");
    }
}
