// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestMisc } from "../BaseTestMisc.t.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { OwnedV2AutoMsgSender } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol";
import { UpgradeSfraxMintRedeemer } from "src/script/Miscellany/UpgradeSfraxMintRedeemer.s.sol";
import { Proxy } from "src/script/Miscellany/Proxy.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";
import { Math } from "@openzeppelin-4/contracts/utils/math/Math.sol";

contract Unit_Test_sFRAXRedeemer is BaseTestMisc {
    uint256 fee;

    function sFraxRedeemerSetup() public {
        console.log("sFraxRedeemerSetup() called");
        super.defaultSetup();

        // Mint FRAX to test users
        frax.mint(alice, 1000e18);
        frax.mint(bob, 1000e18);

        // Mint sFRAX to test users
        sfrax.mint(alice, 1000e18);
        sfrax.mint(bob, 1000e18);

        // Update the vault token price oracle
        sfraxMintRedeemer.updateVaultTknOracle();

        // Note the fee
        fee = sfraxMintRedeemer.fee();
    }

    function test_transferOwnership() public {
        sFraxRedeemerSetup();

        // Nominate Bob
        vm.expectEmit(true, false, false, true);
        emit OwnedV2AutoMsgSender.OwnerNominated(bob);
        sfraxMintRedeemer.nominateNewOwner(bob);

        // Alice fails to accept ownership
        vm.expectRevert(OwnedV2AutoMsgSender.InvalidOwnershipAcceptance.selector);
        hoax(alice);
        sfraxMintRedeemer.acceptOwnership();

        // Bob successfully accepts ownership
        hoax(bob);
        vm.expectEmit(true, true, false, true);
        emit OwnedV2AutoMsgSender.OwnerChanged(address(this), bob);
        sfraxMintRedeemer.acceptOwnership();
        assertEq(sfraxMintRedeemer.owner(), bob);
        assertEq(sfraxMintRedeemer.nominatedOwner(), address(0));
    }

    function test_pricePerShare() public {
        sFraxRedeemerSetup();

        assertEq(sfraxMintRedeemer.pricePerShare(), 1.04e18, "test_pricePerShare");
    }

    function test_convertToShares() public {
        sFraxRedeemerSetup();

        assertApproxEqRel(sfraxMintRedeemer.convertToShares(1e18), 0.961538e18, 0.01e18, "test_convertToShares");
    }

    function test_convertToAssets() public {
        sFraxRedeemerSetup();

        assertEq(sfraxMintRedeemer.convertToAssets(1e18), 1.04e18, "test_convertToAssets");
    }

    function test_mdwrComboView() public {
        sFraxRedeemerSetup();

        // Fetch the view info
        (uint256 _maxAssetsDepositable, uint256 _maxSharesMintable, uint256 _maxAssetsWithdrawable, uint256 _maxSharesRedeemable) = sfraxMintRedeemer.mdwrComboView();

        // Everything should be 0 right now
        assertEq(_maxAssetsDepositable, 0, "[MDWR]: Initial _maxAssetsDepositable");
        assertEq(_maxSharesMintable, 0, "[MDWR]: Initial _maxSharesMintable");
        assertEq(_maxAssetsWithdrawable, 0, "[MDWR]: Initial _maxAssetsWithdrawable");
        assertEq(_maxSharesRedeemable, 0, "[MDWR]: Initial _maxSharesRedeemable");

        // Give the contract some FRAX and sFRAX
        frax.mint(address(sfraxMintRedeemer), 1000e18);
        sfrax.mint(address(sfraxMintRedeemer), 1000e18);

        // Fetch the view info again
        (_maxAssetsDepositable, _maxSharesMintable, _maxAssetsWithdrawable, _maxSharesRedeemable) = sfraxMintRedeemer.mdwrComboView();

        // Check
        assertEq(_maxAssetsDepositable, Math.mulDiv(1040e18, 1e18, (1e18 - fee), Math.Rounding.Up), "[MDWR]: Final _maxAssetsDepositable");
        assertEq(_maxSharesMintable, 1000e18, "[MDWR]: Final _maxSharesMintable");
        assertEq(_maxAssetsWithdrawable, 1000e18, "[MDWR]: Final _maxAssetsWithdrawable");
        // 1000 / 1.04 = ~961.538
        assertApproxEqRel(_maxSharesRedeemable, 961.538e18, 0.01e18, "[MDWR]: Final _maxSharesRedeemable");
    }

    function test_Mint() public {
        sFraxRedeemerSetup();

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve FRAX to the mint/redeemer
        frax.approve(sfxMRAddress, 10e18);

        // Try to mint (fails as there is not any sFRAX in the contract)
        uint256 _max = sfraxMintRedeemer.maxMint(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.ERC4626ExceededMaxMint.selector, bob, 5e18, _max));
        sfraxMintRedeemer.mint(5e18, bob);

        // Stop impersonating Bob
        vm.stopPrank();

        // Give the contract some FRAX and sFRAX
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);

        // Wait three days so the oracles become stale
        _warpToAndRollOne(block.timestamp + (3 * 86_400));

        // Try to mint (should fail due to stale oracle)
        hoax(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.OracleIsStale.selector, "msFRAX"));
        sfraxMintRedeemer.mint(5e18, bob);

        // Update the price oracles
        fraxOracle.setPrice(1e6);
        sfraxOracle.setPrice(1.04e6);
        sfraxMintRedeemer.updateVaultTknOracle();

        // Mint should succeed now
        {
            uint256 _fraxBefore = frax.balanceOf(bob);
            uint256 _sfraxBefore = sfrax.balanceOf(bob);
            hoax(bob);
            uint256 _fraxIn = sfraxMintRedeemer.mint(5e18, bob);
            uint256 _fraxAfter = frax.balanceOf(bob);
            uint256 _sfraxAfter = sfrax.balanceOf(bob);
            assertEq(_fraxBefore - _fraxAfter, _fraxIn, "Mint: Not enough FRAX in");
            assertEq(_sfraxAfter - _sfraxBefore, 5e18, "Mint: Not enough sFRAX out");
        }
    }

    function test_Deposit() public {
        sFraxRedeemerSetup();

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve FRAX to the mint/redeemer
        frax.approve(sfxMRAddress, 10e18);

        // Try to deposit (fails as there is not any sFRAX in the contract)
        uint256 _max = sfraxMintRedeemer.maxDeposit(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.ERC4626ExceededMaxDeposit.selector, bob, 10e18, _max));
        sfraxMintRedeemer.deposit(10e18, bob);

        // Stop impersonating Bob
        vm.stopPrank();

        // Give the contract some FRAX and sFRAX
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);

        // Wait three days so the oracles become stale
        _warpToAndRollOne(block.timestamp + (3 * 86_400));

        // Try to deposit (should fail due to stale oracle)
        hoax(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.OracleIsStale.selector, "msFRAX"));
        sfraxMintRedeemer.deposit(10e18, bob);

        // Update the price oracles
        fraxOracle.setPrice(1e6);
        sfraxOracle.setPrice(1.04e6);
        sfraxMintRedeemer.updateVaultTknOracle();

        // Deposit should succeed now
        {
            uint256 _fraxBefore = frax.balanceOf(bob);
            uint256 _sfraxBefore = sfrax.balanceOf(bob);
            hoax(bob);
            uint256 _sfraxOut = sfraxMintRedeemer.deposit(10e18, bob);
            uint256 _fraxAfter = frax.balanceOf(bob);
            uint256 _sfraxAfter = sfrax.balanceOf(bob);
            assertEq(_fraxBefore - _fraxAfter, 10e18, "Deposit: Not enough FRAX in");
            assertEq(_sfraxAfter - _sfraxBefore, _sfraxOut, "Deposit: Not enough sFRAX out");
        }
    }

    function test_Redeem() public {
        sFraxRedeemerSetup();

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve sFRAX to the mint/redeemer
        sfrax.approve(sfxMRAddress, 10e18);

        // Try to withdraw (fails because owner param is not sender)
        vm.expectRevert(FraxtalERC4626MintRedeemer.TokenOwnerShouldBeSender.selector);
        sfraxMintRedeemer.redeem(5e18, bob, alice);

        // Try to redeem (fails as there is not any FRAX in the contract)
        uint256 _max = sfraxMintRedeemer.maxRedeem(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.ERC4626ExceededMaxRedeem.selector, bob, 5e18, _max));
        sfraxMintRedeemer.redeem(5e18, bob, bob);

        // Stop impersonating Bob
        vm.stopPrank();

        // Give the contract some FRAX and sFRAX
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);

        // Wait three days so the oracles become stale
        _warpToAndRollOne(block.timestamp + (3 * 86_400));

        // Try to redeem (should fail due to stale oracle)
        hoax(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.OracleIsStale.selector, "msFRAX"));
        sfraxMintRedeemer.redeem(5e18, bob, bob);

        // Update the price oracles
        fraxOracle.setPrice(1e6);
        sfraxOracle.setPrice(1.04e6);
        sfraxMintRedeemer.updateVaultTknOracle();

        // Redeem should succeed now
        {
            uint256 _fraxBefore = frax.balanceOf(bob);
            uint256 _sfraxBefore = sfrax.balanceOf(bob);
            hoax(bob);
            uint256 _fraxOut = sfraxMintRedeemer.redeem(5e18, bob, bob);
            uint256 _fraxAfter = frax.balanceOf(bob);
            uint256 _sfraxAfter = sfrax.balanceOf(bob);
            assertEq(_fraxAfter - _fraxBefore, _fraxOut, "Redeem: Not enough FRAX out");
            assertEq(_sfraxBefore - _sfraxAfter, 5e18, "Redeem: Not enough sFRAX in");
        }
    }

    function test_Withdraw() public {
        sFraxRedeemerSetup();

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve sFRAX to the mint/redeemer
        sfrax.approve(sfxMRAddress, 10e18);

        // Try to withdraw (fails because owner param is not sender)
        vm.expectRevert(FraxtalERC4626MintRedeemer.TokenOwnerShouldBeSender.selector);
        sfraxMintRedeemer.withdraw(5e18, bob, alice);

        // Try to withdraw (fails as there is not any FRAX in the contract)
        uint256 _max = sfraxMintRedeemer.maxWithdraw(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.ERC4626ExceededMaxWithdraw.selector, bob, 5e18, _max));
        sfraxMintRedeemer.withdraw(5e18, bob, bob);

        // Stop impersonating Bob
        vm.stopPrank();

        // Give the contract some FRAX and sFRAX
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);

        // Wait three days so the oracles become stale
        _warpToAndRollOne(block.timestamp + (3 * 86_400));

        // Try to redeem (should fail due to stale oracle)
        hoax(bob);
        vm.expectRevert(abi.encodeWithSelector(FraxtalERC4626MintRedeemer.OracleIsStale.selector, "msFRAX"));
        sfraxMintRedeemer.withdraw(5e18, bob, bob);

        // Update the price oracles
        fraxOracle.setPrice(1e6);
        sfraxOracle.setPrice(1.04e6);
        sfraxMintRedeemer.updateVaultTknOracle();

        // Withdrawal should succeed now
        {
            uint256 _fraxBefore = frax.balanceOf(bob);
            uint256 _sfraxBefore = sfrax.balanceOf(bob);
            hoax(bob);
            uint256 _sfraxIn = sfraxMintRedeemer.withdraw(5e18, bob, bob);
            uint256 _fraxAfter = frax.balanceOf(bob);
            uint256 _sfraxAfter = sfrax.balanceOf(bob);
            assertEq(_fraxAfter - _fraxBefore, 5e18, "Withdraw: Not enough FRAX out");
            assertEq(_sfraxBefore - _sfraxAfter, _sfraxIn, "Withdraw: Not enough sFRAX in");
        }
    }

    function test_priceCannotChangeInterBlock() public {
        sFraxRedeemerSetup();
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);

        (uint256 minted_front,) = _depositAndLogBob();

        sfraxOracle.setPrice(1.06e6);
        fraxOracle.setPrice(1e6);

        (uint256 minted_back,) = _depositAndLogBob();

        assertEq({ a: minted_front, b: minted_back, err: "// NOTICE: User should not be able to front and back run oracle update" });
    }

    function test_Mint_alwaysPricedLatesCurrentOracle() public {
        sFraxRedeemerSetup();
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);

        vm.warp(block.timestamp + 1 minutes);

        sfraxOracle.setPrice(1.06e6);
        fraxOracle.setPrice(1e6);

        (, uint256 price) = _depositAndLogBob();

        assertEq({ a: 1.06e18, b: price, err: "// NOTICE: User should not be able to front and back run oracle update" });
    }

    function _previewDepositMintWithdrawRedeem() internal {
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);

        // Set fee to 1%
        sfraxMintRedeemer.setMintRedeemFee(0.01e18);

        // // Set fee to 0.01%
        // sfraxMintRedeemer.setMintRedeemFee(0.0001e18);

        // // Set fee to 0%
        // sfraxMintRedeemer.setMintRedeemFee(0.00e18);

        // Impersonate Bob
        vm.startPrank(bob);

        // Approve FRAX to the sfraxMintRedeemer
        frax.approve(address(sfraxMintRedeemer), 4e18);

        // Do Deposit -> Mint first
        console.log("\n----- Common Info -----");
        console.log("getLatestUnderlyingPriceE18: ", sfraxMintRedeemer.getLatestUnderlyingPriceE18());
        console.log("getVaultTknPriceStoredE18: ", sfraxMintRedeemer.getVaultTknPriceStoredE18());

        // Do Deposit -> Mint first
        console.log("\n----- Deposit / Mint -----");

        // preview Deposit
        uint256 _sharesOutPreview = sfraxMintRedeemer.previewDeposit(1e18);
        console.log("previewDeposit _sharesOutPreview: ", _sharesOutPreview);

        // previewMint using previewDeposit result
        uint256 _assetsInPreview = sfraxMintRedeemer.previewMint(_sharesOutPreview);
        console.log("previewMint _assetsInPreview: ", _assetsInPreview);

        // Check
        assertEq(_assetsInPreview, 1e18, "Deposit / Mint reciprocal amounts mismatch");

        // Now do Withdraw / Redeem
        console.log("\n----- Withdraw / Redeem -----");

        // preview Withdraw
        uint256 _sharesInPreview = sfraxMintRedeemer.previewWithdraw(1e18);
        console.log("previewWithdraw _sharesInPreview: ", _sharesInPreview);

        // preview Redeem
        uint256 _assetsOutPreview = sfraxMintRedeemer.previewRedeem(_sharesInPreview);
        console.log("previewRedeem _assetsOutPreview: ", _assetsOutPreview);

        // Check. Can be off by 1 wei
        assertApproxEqRel(_assetsOutPreview, 1e18, 1 wei, "Withdraw / Redeem reciprocal amounts mismatch");

        vm.stopPrank();
    }

    function test_previewDepositMintWithdrawRedeem() public {
        sFraxRedeemerSetup();
        _previewDepositMintWithdrawRedeem();
    }

    function test_feeOn_Deposit() public {
        sFraxRedeemerSetup();
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);
        uint256 fee = sfraxMintRedeemer.fee();

        (uint256 sFraxReceived, uint256 price) = _depositAndLogBob();

        uint256 _assetsInPostFee = 10e18 - Math.mulDiv(10e18, fee, 1e18, Math.Rounding.Up);
        uint256 _expectedReceived = Math.mulDiv(_assetsInPostFee, 1e18, price, Math.Rounding.Down);

        console.log("Assets in including Fees: ", _assetsInPostFee);
        console.log("Sfrax derived: ", Math.mulDiv(_assetsInPostFee, 1e18, price, Math.Rounding.Down));

        assertEq({ a: _expectedReceived, b: sFraxReceived, err: "// THEN: Vault token received not expected" });
    }

    function test_feeOn_Mint() public {
        sFraxRedeemerSetup();
        frax.mint(address(sfraxMintRedeemer), 100_000e18);
        sfrax.mint(address(sfraxMintRedeemer), 100_000e18);
        uint256 fee = sfraxMintRedeemer.fee();

        uint256 toApprove = sfraxMintRedeemer.previewMint(10e18);
        uint256 fraxBefore = frax.balanceOf(bob);

        vm.startPrank(bob);
        frax.approve(sfxMRAddress, toApprove);
        uint256 fraxOwed = sfraxMintRedeemer.mint(10e18, bob);

        uint256 fraxAfter = frax.balanceOf(bob);

        uint256 assetIn = Math.mulDiv(10e18, sfraxMintRedeemer.getVaultTknPriceStoredE18(), 1e18, Math.Rounding.Up);
        assetIn = Math.mulDiv(assetIn, 1e18, (1e18 - fee), Math.Rounding.Up);

        assertEq({ a: fraxBefore - fraxAfter, b: fraxOwed, err: "// THEN: return is not eq to state change" });

        assertEq({ a: fraxBefore - fraxAfter, b: assetIn, err: "// THEN: Mint amount does not reflect fees" });

        console.log("The frax used to mint 10 shares: ", fraxBefore - fraxAfter);
    }

    function test_feeOn_Redeem() public {
        test_feeOn_Mint();
        uint256 fraxBefore = frax.balanceOf(bob);
        uint256 fee = sfraxMintRedeemer.fee();

        /// @notice prank on `bob` still active
        sfrax.approve(sfxMRAddress, 10e18);
        uint256 fraxOwed = sfraxMintRedeemer.redeem(10e18, bob, bob);

        uint256 fraxAfter = frax.balanceOf(bob);

        uint256 assetOut = Math.mulDiv(10e18, sfraxMintRedeemer.getVaultTknPriceStoredE18(), 1e18, Math.Rounding.Down);
        assetOut = Math.mulDiv((1e18 - fee), assetOut, 1e18, Math.Rounding.Up);

        assertEq({ a: fraxOwed, b: fraxAfter - fraxBefore, err: "// THEN: return is not eq to state change" });

        assertEq({ a: fraxOwed, b: assetOut, err: "// THEN: fees not factored as expected" });
    }

    function test_feeOn_Withdraw() public {
        test_feeOn_Mint();
        uint256 sfraxBefore = sfrax.balanceOf(bob);
        uint256 fee = sfraxMintRedeemer.fee();

        /// @notice prank on `bob` still active
        sfrax.approve(sfxMRAddress, 10e18);
        uint256 sfraxIn = sfraxMintRedeemer.withdraw(10e18, bob, bob);

        uint256 sfraxAfter = sfrax.balanceOf(bob);

        assertEq({ a: sfraxIn, b: sfraxBefore - sfraxAfter, err: "// THEN: return is not eq to state change" });

        uint256 assetOutWithFee = Math.mulDiv(10e18, 1e18, (1e18 - fee), Math.Rounding.Up);
        uint256 sharedIn = Math.mulDiv(assetOutWithFee, 1e18, sfraxMintRedeemer.getVaultTknPriceStoredE18(), Math.Rounding.Up);

        assertEq({ a: sfraxIn, b: sharedIn, err: "// THEN: fees not factored as expected" });
    }

    function test_setMintRedeemFee_onlyOwner_reverts() public {
        sFraxRedeemerSetup();
        vm.expectRevert(OwnedV2AutoMsgSender.OnlyOwner.selector);
        vm.prank(address(0xBAD));
        sfraxMintRedeemer.setMintRedeemFee(1e8);
    }

    function test_setMintRedeemFee_invalidInput() public {
        sFraxRedeemerSetup();
        vm.expectRevert(bytes("Fee must be a fraction of underlying"));
        sfraxMintRedeemer.setMintRedeemFee(1e18);
    }

    function test_setMintRedeemFee() public {
        sFraxRedeemerSetup();
        sfraxMintRedeemer.setMintRedeemFee(2e8);
        assertEq({ a: 2e8, b: sfraxMintRedeemer.fee(), err: "// THEN: fee not changed as expected" });
    }

    // HELPERS
    // ===================================================
    function _depositAndLogBob() internal returns (uint256 sFraxMinted, uint256 priceMinted) {
        vm.startPrank(bob);

        uint256 sfraxBefore = sfrax.balanceOf(bob);
        frax.approve(sfxMRAddress, 10e18);
        uint256 minted = sfraxMintRedeemer.deposit(10e18, bob);
        uint256 sfraxAfter = sfrax.balanceOf(bob);

        sFraxMinted = sfraxAfter - sfraxBefore;
        priceMinted = sfraxMintRedeemer.getVaultTknPriceStoredE18();
        vm.stopPrank();

        console.log("==============_depositAndLogBob==============");
        console.log("the sfrax minted to bob: ", sFraxMinted);
        console.log("The mint price: ", sfraxMintRedeemer.getVaultTknPriceStoredE18());
        console.log("=============================================");
    }
}
