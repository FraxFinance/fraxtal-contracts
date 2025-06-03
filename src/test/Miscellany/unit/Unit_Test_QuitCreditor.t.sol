// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestMisc } from "../BaseTestMisc.t.sol";
import { FraxFarmQuitCreditor_UniV3 } from "src/contracts/Miscellany/FraxFarmQuitCreditor/FraxFarmQuitCreditor_UniV3.sol";
import { L1QuitCreditorReceiverConverter } from "src/contracts/Miscellany/FraxFarmQuitCreditor/L1QuitCreditorReceiverConverter.sol";
import { DeployL1QuitCreditorReceiverConverters } from "src/script/Miscellany/DeployL1QuitCreditorReceiverConverters.s.sol";
import { IERC20Metadata } from "@openzeppelin-4/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IFrax } from "src/contracts/Miscellany/interfaces/IFrax.sol";
import { IFXB } from "src/contracts/Miscellany/interfaces/IFXB.sol";
import { ICrossDomainMessenger } from "src/contracts/Miscellany/FraxFarmQuitCreditor/ICrossDomainMessenger.sol";
import { OwnedV2 } from "src/contracts/Miscellany/OwnedV2.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Unit_Test_QuitCreditor is BaseTestMisc {
    // Avoid stack-too-deep
    // -----------------------------
    IFrax public fxtlFRAX;
    IFXB public fxb20291231;
    address public nftOriginalHolder = 0x36A87d1E3200225f881488E4AEedF25303FebcAe;
    DeployL1QuitCreditorReceiverConverters fxtlL1QuitCdRecCvtrDeployer;
    L1QuitCreditorReceiverConverter fxtlL1QuitCdRecCvtrFRAXDAI;
    L1QuitCreditorReceiverConverter fxtlL1QuitCdRecCvtrFRAXUSDC;
    ICrossDomainMessenger messenger;
    uint256 public _minGasLimit;
    uint256[5] public _tokensOut;
    uint256[5] public _tokensOutTmp;
    uint256 public _usdCredit;
    uint256 public _usdCreditTmp;
    bytes _encodedMessage0;
    bytes _encodedMessage1;
    uint256[3] public _aliceTknsBefore;
    uint256[3] public _qcTknsBefore;
    uint256[3] public _testCtctTknsBefore;
    uint256 public _fxsDiff;
    uint256 public _aliceTkn0Diff;
    uint256 public _aliceTkn1Diff;
    uint256 public _qcTkn0Diff;
    uint256 public _qcTkn1Diff;
    uint256 public _testCtctTkn0Collected;
    uint256 public _testCtctTkn1Collected;

    function QuitCreditorSetup() public {
        console.log("QuitCreditorSetup() called");
        super.defaultSetup();

        // Fetch the _minGasLimit
        _minGasLimit = quitCreditorFRAXUSDC.minGasLimit();

        // Enable migrations and assign the quitCreditorFRAXUSDC as a migrator
        // hoax(fraxFarmUniV3FraxUsdc.owner());
        // fraxFarmUniV3FraxUsdc.toggleMigrations();
        hoax(fraxFarmUniV3FraxUsdc.owner());
        fraxFarmUniV3FraxUsdc.addMigrator(address(quitCreditorFRAXUSDC));

        // Impersonate the NFT Holder
        vm.startPrank(nftOriginalHolder);

        // Give Alice 4 UniV3 FRAX/USDC NFTs ($690.55 total value)
        univ3NftPositionMgr.safeTransferFrom(nftOriginalHolder, alice, 74_583, ""); // $73.16
        univ3NftPositionMgr.safeTransferFrom(nftOriginalHolder, alice, 85_702, ""); // $502.37
        univ3NftPositionMgr.safeTransferFrom(nftOriginalHolder, alice, 83_592, ""); // $24.01
        univ3NftPositionMgr.safeTransferFrom(nftOriginalHolder, alice, 83_529, ""); // $91.01

        // Stop impersonating the NFT Holder
        vm.stopPrank();
    }

    function BasicAliceSetup() public {
        QuitCreditorSetup();

        // Impersonate Alice
        vm.startPrank(alice);

        // Approve the NFTs to the farm
        univ3NftPositionMgr.approve(address(fraxFarmUniV3FraxUsdc), 74_583);
        univ3NftPositionMgr.approve(address(fraxFarmUniV3FraxUsdc), 85_702);
        univ3NftPositionMgr.approve(address(fraxFarmUniV3FraxUsdc), 83_592);
        univ3NftPositionMgr.approve(address(fraxFarmUniV3FraxUsdc), 83_529);

        // Lock the NFTs into the farm
        fraxFarmUniV3FraxUsdc.stakeLocked(74_583, 4 * 604_800);
        fraxFarmUniV3FraxUsdc.stakeLocked(85_702, 8 * 604_800);
        fraxFarmUniV3FraxUsdc.stakeLocked(83_592, 12 * 604_800);
        fraxFarmUniV3FraxUsdc.stakeLocked(83_529, 16 * 604_800);

        // Alice allows the quitCreditorFRAXUSDC to be a migrator for her
        fraxFarmUniV3FraxUsdc.stakerAllowMigrator(address(quitCreditorFRAXUSDC));

        // Stop impersonating alice
        vm.stopPrank();

        uint256 _temp = fraxFarmUniV3FraxUsdc.combinedWeightOf(nftOriginalHolder);
        console.log("nftOriginalHolder combinedWeightOf: ", _temp);
    }

    function test_exitForCredit() public {
        BasicAliceSetup();

        // Note Alice's token balances
        _aliceTknsBefore = [mainnetFXS.balanceOf(alice), qcToken0.balanceOf(alice), qcToken1.balanceOf(alice)];

        // Note the QuitCreditor's token balances
        _qcTknsBefore = [mainnetFXS.balanceOf(address(quitCreditorFRAXUSDC)), qcToken0.balanceOf(address(quitCreditorFRAXUSDC)), qcToken1.balanceOf(address(quitCreditorFRAXUSDC))];

        // Trigger Alice's exit for one NFT, with credits eventually going to Bob on Fraxtal
        hoax(alice);
        (, _tokensOut, _usdCredit, _encodedMessage0) = quitCreditorFRAXUSDC.exitOneForCredit(bob, 74_583);

        // Trigger Alice's exit for her remaining NFTs, with credits eventually going to Bob on Fraxtal
        hoax(alice);
        (, _tokensOutTmp, _usdCreditTmp, _encodedMessage1) = quitCreditorFRAXUSDC.exitAllForCredit(bob);

        // Sum the output amounts
        _tokensOut[0] += _tokensOutTmp[0];
        _tokensOut[1] += _tokensOutTmp[1];
        _tokensOut[2] += _tokensOutTmp[2];
        _tokensOut[3] += _tokensOutTmp[3];
        _tokensOut[4] += _tokensOutTmp[4];
        _usdCredit += _usdCreditTmp;

        // Do checks
        {
            // Check Alice
            {
                // Weight
                uint256 _aliceFarmBalance = fraxFarmUniV3FraxUsdc.combinedWeightOf(alice);
                assertEq(_aliceFarmBalance, 0, "Alice should not have anything left in the farm");

                // FXS Rewards
                _fxsDiff = mainnetFXS.balanceOf(alice) - _aliceTknsBefore[0];
                assertEq(_fxsDiff, _tokensOut[0], "Alice _tokensOut[0] (FXS) mismatch with balanceOf diff");

                // Other tokens (fees)
                _aliceTkn0Diff = qcToken0.balanceOf(alice) - _aliceTknsBefore[1];
                _aliceTkn1Diff = qcToken1.balanceOf(alice) - _aliceTknsBefore[2];
                assertEq(_aliceTkn0Diff, _tokensOut[1], "Alice _tokensOut[1] (token0 fees) mismatch with balanceOf diff");
                assertEq(_aliceTkn1Diff, _tokensOut[2], "Alice _tokensOut[2] (token1 fees) mismatch with balanceOf diff");
            }

            // Check QuitCreditor
            {
                // FXS Rewards
                _fxsDiff = mainnetFXS.balanceOf(address(quitCreditorFRAXUSDC)) - _qcTknsBefore[0];
                assertEq(_fxsDiff, 0, "QuitCreditor should not have collected any FXS");
                assertEq(_fxsDiff, _tokensOut[0], "QuitCreditor _tokensOut[0] (FXS) mismatch with balanceOf diff");

                // Other tokens (principal)
                _qcTkn0Diff = qcToken0.balanceOf(address(quitCreditorFRAXUSDC)) - _qcTknsBefore[1];
                _qcTkn1Diff = qcToken1.balanceOf(address(quitCreditorFRAXUSDC)) - _qcTknsBefore[2];
                uint256 _valueCollectedE18 = (_qcTkn0Diff * (10 ** qcMissingDecimals[0])) + (_qcTkn1Diff * (10 ** qcMissingDecimals[1]));
                assertApproxEqRel(_valueCollectedE18, 690.55e18, 0.01e18, "QuitCreditor should have collected approx $690.55 in tokens");
                assertEq(_qcTkn0Diff, _tokensOut[3], "QuitCreditor _tokensOut[3] (token0 principal) mismatch with balanceOf diff");
                assertEq(_qcTkn1Diff, _tokensOut[4], "QuitCreditor _tokensOut[4] (token1 principal) mismatch with balanceOf diff");
            }

            // Check USD credit
            assertApproxEqRel(_usdCredit, 690.55e18, 0.01e18, "USD credit should have been approx $690.55");
        }

        // Note this test contract token balances
        _testCtctTknsBefore = [mainnetFXS.balanceOf(address(this)), qcToken0.balanceOf(address(this)), qcToken1.balanceOf(address(this))];

        // Collect all the token0 and token1
        quitCreditorFRAXUSDC.collectAllTkn0AndTkn1();

        // Make sure the proper amount was collected
        _testCtctTkn0Collected = qcToken0.balanceOf(address(this)) - _testCtctTknsBefore[1];
        _testCtctTkn1Collected = qcToken1.balanceOf(address(this)) - _testCtctTknsBefore[2];
        assertEq(_testCtctTkn0Collected, _qcTkn0Diff, "Test Contract collected token0 mismatch with QuitCreditor diff");
        assertEq(_testCtctTkn1Collected, _qcTkn1Diff, "Test Contract collected token1 mismatch with QuitCreditor diff");

        // Switch to Fraxtal
        vm.createSelectFork(vm.envString("FRAXTAL_RPC_URL"), 7_247_251);

        // Deploy the L1QuitCreditorReceiverConverter
        fxtlL1QuitCdRecCvtrDeployer = new DeployL1QuitCreditorReceiverConverters();
        (fxtlL1QuitCdRecCvtrFRAXDAI, fxtlL1QuitCdRecCvtrFRAXUSDC) = fxtlL1QuitCdRecCvtrDeployer.runTest();

        // Set the quitCreditorFRAXUSDC address on the L1QuitCreditorReceiverConverter
        fxtlL1QuitCdRecCvtrFRAXUSDC.setQuitCreditorAddress(address(quitCreditorFRAXUSDC));

        // Initialize FRAX and FXB20291231
        fxtlFRAX = IFrax(0xFc00000000000000000000000000000000000001);
        fxb20291231 = IFXB(0xF1e2b576aF4C6a7eE966b14C810b772391e92153);

        // Mint FRAX to this contract
        hoax(0x4200000000000000000000000000000000000010);
        fxtlFRAX.mint(address(this), 100_000e18);

        // Mint FXB20291231 and dump it into the fxtlL1QuitCdRecCvtr
        fxtlFRAX.approve(address(fxb20291231), 100_000e18);
        fxb20291231.mint(address(fxtlL1QuitCdRecCvtrFRAXUSDC), 10_000e18);

        // Initialize the (L2) CrossDomainMessenger
        messenger = ICrossDomainMessenger(0x4200000000000000000000000000000000000007);

        // Get the current nonce
        uint256 _currNonce = messenger.messageNonce();

        // Impersonate the relayMessage caller and relay the messages to the L1QuitCreditorReceiverConverter
        hoax(0x237cCc31Bc076b3D515F60fBC81Fdde0b0D553fE);
        messenger.relayMessage(_currNonce, address(quitCreditorFRAXUSDC), address(fxtlL1QuitCdRecCvtrFRAXUSDC), 0, _minGasLimit, _encodedMessage0);

        hoax(0x237cCc31Bc076b3D515F60fBC81Fdde0b0D553fE);
        messenger.relayMessage(_currNonce, address(quitCreditorFRAXUSDC), address(fxtlL1QuitCdRecCvtrFRAXUSDC), 0, _minGasLimit, _encodedMessage1);

        // Bob should have FXB20291231 at $0.794 per FXB
        uint256 _bobFxbBalance = fxb20291231.balanceOf(bob);
        assertApproxEqRel(_bobFxbBalance, 869.71e18, 0.01e18, "Bob should have gotten about 869.71 FXB20291231");
    }
}
