// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../LiveMainnetCGTUpgradeBaseTest.t.sol";
import { IERC20ExPPOMWrapped } from "src/contracts/Fraxtal/universal/interfaces/IERC20ExPPOMWrapped.sol";
import { IERC20PermitPermissionedOptiMintable } from "src/contracts/Fraxtal/universal/interfaces/IERC20PermitPermissionedOptiMintable.sol";
import { DecimalStringHelper } from "src/test/Fraxtal/helpers/DecimalStringHelper.sol";
import { IProxyAdmin } from "@eth-optimism/contracts-bedrock/src/universal/interfaces/IProxyAdmin.sol";
import { SigUtils } from "src/test/Fraxtal/utils/SigUtils.sol";
import { Storage } from "src/script/Fraxtal/testnet/Storage.sol";
import { StorageSetterRestricted } from "src/script/Fraxtal/testnet/StorageSetterRestricted.sol";

contract Test_UpgradedWFRAX is LiveMainnetCGTUpgradeBaseTest {
    // using stdStorage for StdStorage;
    using DecimalStringHelper for uint256;

    // Contracts
    IERC20PermitPermissionedOptiMintable public FXS_L2; // added for clarity

    // Test users
    address[3] public tstUsers;
    uint256[3] public tstUserPkeys;
    address public allowanceReceiver = 0x5f4E3B89133a578E128eb3b238aa502C675cc210;
    address public permitSpender = 0x36A87d1E3200225f881488E4AEedF25303FebcAe;

    // Before and after comparisons
    address[3] public addressesBefore;
    address[3] public addressesAfter;
    uint256[3] public allowancesBefore;
    uint256[3] public allowancesAfter;
    uint256[3] public noncesBefore;
    uint256[3] public noncesAfter;
    uint256[3] public permitAllowancesBefore;
    uint256[3] public permitAllowancesAfter;
    uint256[3] public balancesBefore;
    uint256[3] public balancesAfter;
    string[3] public stringsBefore;
    string[3] public stringsAfter;
    uint256 public totalSupplyBefore;
    uint256 public totalSupplyAfter;
    PermitDetails[3] public prmDetails;

    bool public USING_DEVNET = true;

    struct PermitDetails {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 timestamp;
    }

    uint256 public USER_ETH_START = 10e18;

    function setUp() public {
        // Set everything up but don't do upgrades yet
        defaultSetup();

        // Switch to L2
        vm.selectFork(l2ForkID);

        // Initialize FXS and the SigUtils beforehand
        FXS_L2 = IERC20PermitPermissionedOptiMintable(address(wFRAX));
        sigUtils_FXS = new SigUtils(FXS_L2.DOMAIN_SEPARATOR());
        vm.makePersistent(address(FXS_L2), address(sigUtils_FXS));

        // Initialize test users
        tstUserPkeys = [0xA11CE, 0xB0B, 0xc0];
        tstUsers = [payable(vm.addr(tstUserPkeys[0])), payable(vm.addr(tstUserPkeys[1])), payable(vm.addr(tstUserPkeys[2]))];

        // Label test users
        vm.label(tstUsers[0], "TU1");
        vm.label(tstUsers[1], "TU2");
        vm.label(tstUsers[2], "TU3");

        // Give mnemonic users ETH
        vm.deal(junkDeployerAddress, 100e18);
        vm.deal(junkDeployerHelperAddress, 100e18);

        // Give test users ETH and FXS
        for (uint256 i = 0; i < tstUsers.length; i++) {
            // ETH
            vm.deal(tstUsers[i], 10e18);
            console.log("Balance initial (dec'd): ", address(tstUsers[i]).balance.decimalString(18, false));

            // FXS
            vm.prank(FXS_L2.bridge());
            FXS_L2.mint(tstUsers[i], 1000e18);
        }

        // Set test allowances
        for (uint256 i = 0; i < tstUsers.length; i++) {
            vm.prank(tstUsers[i]);
            FXS_L2.approve(allowanceReceiver, (i + 1) * 100e18);
        }
    }

    // function upgradeWFrax() public {
    //     // Become the proxy admin owner
    //     vm.startPrank(FRAXTAL_L2_PROXY_ADMIN_OWNER);

    //     // Deploy the impl for wFRAX
    //     IERC20ExPPOMWrapped theImpl = new IERC20ExPPOMWrapped(FRAXTAL_L2_FRAXTAL_SAFE, FRAXTAL_L2_FRAXTAL_SAFE, "Wrapped Frax", "wFRAX");

    //     // Note the total supply
    //     uint256 _tSupply = FXS_L2.totalSupply();

    //     // Dump _tSupply gas tokens (ETH here, for now) into wFRAX
    //     vm.deal(FRAXTAL_L2_FXS, _tSupply);

    //     console.log("xxxxxxxxxxxxxxxxxxx");
    //     // NEED TO MASK WITH LENGTH * 2 for strings < 32 bytes

    //     // Frax Share: 0x4672617820536861726500000000000000000000000000000000000000000014
    //     console.log("\nFrax Share");
    //     console.logBytes32(vm.load(FRAXTAL_L2_FXS, bytes32(uint256(3))));
    //     // console.logBytes32(bytes32("Frax Share") | bytes32(uint256(20)));

    //     // FXS: 0x4658530000000000000000000000000000000000000000000000000000000006
    //     console.log("\nFXS");
    //     console.logBytes32(vm.load(FRAXTAL_L2_FXS, bytes32(uint256(4))));
    //     // console.logBytes32(bytes32("FXS") | bytes32(uint256(6)));

    //     // Wrapped Frax:
    //     console.log("\nWrapped Frax");
    //     console.logBytes32(bytes32("Wrapped Frax") | bytes32(uint256(24)));

    //     // wFRAX: 0x774652415800000000000000000000000000000000000000000000000000000a
    //     console.log("\nwFRAX");
    //     console.logBytes32(bytes32("wFRAX") | bytes32(uint256(10)));

    //     // Need a StorageSetterRestricted to manipulate the proxy storage for the new name and symbol
    //     StorageSetterRestricted storageSetter = new StorageSetterRestricted();

    //     console.log("\nwFRAX StorageSetterRestricted deployed at", address(storageSetter));

    //     // Prepare the storage setter with the new name and symbol
    //     StorageSetterRestricted.Slot[] memory slotsToWrite = new StorageSetterRestricted.Slot[](2);
    //     slotsToWrite[0] = StorageSetterRestricted.Slot({ key: bytes32(uint256(3)), value: bytes32("Wrapped Frax") | bytes32(uint256(24)) });
    //     slotsToWrite[1] = StorageSetterRestricted.Slot({ key: bytes32(uint256(4)), value: bytes32("wFRAX") | bytes32(uint256(10)) });

    //     // Write the altered slots to the proxy storage
    //     IProxyAdmin(FRAXTAL_L2_PROXY_ADMIN).upgradeAndCall(payable(address(FRAXTAL_L2_FXS)), address(storageSetter), abi.encodeWithSignature("clearSlotZero()"));

    //     // Initialize wFRAX variable
    //     wFRAX = IERC20ExPPOMWrapped(payable(FRAXTAL_L2_FXS));

    //     // Make sure the storage got updated properly
    //     assertEq(wFRAX.name(), "Wrapped Frax", "name not stored properly");
    //     assertEq(wFRAX.symbol(), "wFRAX", "symbol not stored properly");

    //     // Set wFRAX SigUtils
    //     sigUtils_wFRAX = new SigUtils(wFRAX.DOMAIN_SEPARATOR());
    //     console.log("New sigUtils_wFRAX at: ", address(sigUtils_wFRAX));

    //     vm.stopPrank();
    // }

    function test_wFRAXUpgrading() public {
        setUp();

        // Snapshot the state beforehand
        // https://book.getfoundry.sh/cheatcodes/state-snapshots
        // uint256 snapshotBefore = vm.snapshotState();
        // See also: https://book.getfoundry.sh/cheatcodes/start-state-diff-recording

        // Check the state before and after
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★★★ STATE TESTS ★★★★★★★★★★★★★★★★★★★★★★★★★");
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");

        // ================================================
        // Note the state before (jank method)
        // ================================================
        console.log("============= STATE BEFORE =============");

        // Strings
        stringsBefore[0] = FXS_L2.name();
        stringsBefore[1] = FXS_L2.symbol();
        stringsBefore[2] = FXS_L2.version();
        console.log("name: ", stringsBefore[0]);
        console.log("symbol: ", stringsBefore[1]);
        console.log("version: ", stringsBefore[2]);

        // Total Supply
        totalSupplyBefore = FXS_L2.totalSupply();
        console.log("totalSupply: ", totalSupplyBefore);

        // Note balances, allowances, and nonces before
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("-------- %s --------", vm.getLabel(tstUsers[i]));
            balancesBefore[i] = FXS_L2.balanceOf(tstUsers[i]);
            allowancesBefore[i] = FXS_L2.allowance(tstUsers[i], allowanceReceiver);
            noncesBefore[i] = FXS_L2.nonces(tstUsers[i]);

            console.log("Balance (dec'd): ", balancesBefore[i].decimalString(18, false));
            console.log("Allowance [normal] (dec'd): ", allowancesBefore[i].decimalString(18, false));
            console.log("Nonces: ", noncesBefore[i]);
        }

        // Upgrade
        // doL2Upgrades(); // L2 only
        doUpgrades(); // L2, then L1

        // ================================================
        // Note the state after (jank method)
        // ================================================
        console.log("============= STATE AFTER =============");

        // Switch to L2
        vm.selectFork(l2ForkID);

        // Give mnemonic users ETH again
        vm.deal(junkDeployerAddress, 100e18);
        vm.deal(junkDeployerHelperAddress, 100e18);

        // Strings
        stringsAfter[0] = wFRAX.name();
        stringsAfter[1] = wFRAX.symbol();
        stringsAfter[2] = wFRAX.version();
        console.log("name: ", stringsAfter[0]);
        console.log("symbol: ", stringsAfter[1]);
        console.log("version: ", stringsAfter[2]);

        // Total Supply
        totalSupplyAfter = wFRAX.totalSupply();
        console.log("totalSupply: ", totalSupplyAfter);
        assertEq(totalSupplyBefore, totalSupplyAfter, "totalSupply mismatch");

        // Note balances and allowances after
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("----- %s -----", vm.getLabel(tstUsers[i]));
            balancesAfter[i] = wFRAX.balanceOf(tstUsers[i]);
            allowancesAfter[i] = wFRAX.allowance(tstUsers[i], allowanceReceiver);
            noncesAfter[i] = FXS_L2.nonces(tstUsers[i]);

            console.log("Balance (dec'd): ", balancesAfter[i].decimalString(18, false));
            console.log("Allowance [normal] (dec'd): ", allowancesAfter[i].decimalString(18, false));
            console.log("Nonces: ", noncesAfter[i]);

            // Assert that they did not change
            assertEq(balancesBefore[i], balancesAfter[i], "Balance mismatch");
            assertEq(allowancesBefore[i], allowancesAfter[i], "Allowance mismatch");

            // Check permit allowance beforehand
            permitAllowancesBefore[i] = wFRAX.allowance(tstUsers[i], permitSpender);
            console.log("Allowance [permit, before] (dec'd): ", permitAllowancesBefore[i].decimalString(18, false));
            assertEq(permitAllowancesBefore[i], 0, "Permit allowance should be 0 beforehand");

            // Sign a test permit
            uint256 timestampToUse = block.timestamp + (1 days);
            uint256 permitNonce = FXS_L2.nonces(tstUsers[i]);
            SigUtils.Permit memory permit = SigUtils.Permit({ owner: tstUsers[i], spender: permitSpender, value: 10e18, nonce: permitNonce, deadline: timestampToUse });
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(tstUserPkeys[i], sigUtils_wFRAX.getTypedDataHash(permit));

            console.log("Signed the permit");
            prmDetails[i] = PermitDetails(v, r, s, timestampToUse);
            // console.log("---v---");
            // console.log(v);
            // console.log("---r---");
            // console.logBytes32(r);
            // console.log("---s---");
            // console.logBytes32(s);
            // console.log("---timestampToUse---");
            // console.log(timestampToUse);

            // Use the permit
            vm.prank(permitSpender);
            FXS_L2.permit(tstUsers[i], permitSpender, 10e18, prmDetails[i].timestamp, prmDetails[i].v, prmDetails[i].r, prmDetails[i].s);

            // Check permit allowance and nonce after
            permitAllowancesAfter[i] = wFRAX.allowance(tstUsers[i], permitSpender);
            console.log("Allowance [permit, after] (dec'd): ", permitAllowancesAfter[i].decimalString(18, false));
            assertEq(permitAllowancesAfter[i], 10e18, "Permit allowance should be 10 afterwards");
            assertEq(FXS_L2.nonces(tstUsers[i]), permitNonce + 1, "Permit nonce should have increased");
        }

        // Function testing
        // mint, burn, etc and some other functions should not work now...
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★ FUNCTION TESTS ★★★★★★★★★★★★★★★★★★★★★★★★");
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");

        // Transfer
        console.log("============= TRANSFER =============");
        for (uint256 i = 0; i < tstUsers.length; i++) {
            // Try to transfer too much (should fail)
            vm.prank(tstUsers[i]);
            vm.expectRevert();
            wFRAX.transfer(allowanceReceiver, 100_000e18);

            // Try to transferFrom without an allowance
            vm.prank(tstUsers[i]);
            vm.expectRevert();
            wFRAX.transferFrom(allowanceReceiver, tstUsers[i], 100_000e18);

            // Approve to the allowanceReceiver
            vm.prank(tstUsers[i]);
            wFRAX.approve(allowanceReceiver, 1e18);

            // allowanceReceiver should be able to transferFrom, both to himself and to elsewhere.
            vm.prank(allowanceReceiver);
            wFRAX.transferFrom(tstUsers[i], allowanceReceiver, 0.5e18);
            vm.prank(allowanceReceiver);
            wFRAX.transferFrom(tstUsers[i], permitSpender, 0.5e18);

            // Cannot spend more than allowed
            vm.prank(allowanceReceiver);
            vm.expectRevert();
            wFRAX.transferFrom(tstUsers[i], permitSpender, 0.5e18);
        }

        // Deposit
        console.log("============= DEPOSIT =============");
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("----- %s -----", vm.getLabel(tstUsers[i]));
            // Note balances
            uint256 _ETHBefore = tstUsers[i].balance;
            uint256 _wFRAXBefore = wFRAX.balanceOf(tstUsers[i]);
            console.log("ETH before (dec'd): ", _ETHBefore.decimalString(18, false));
            console.log("wFRAX before (dec'd): ", _wFRAXBefore.decimalString(18, false));

            // Deposit
            vm.prank(tstUsers[i]);
            wFRAX.deposit{ value: 1e18 }();

            // Check balances
            console.log("ETH after (dec'd): ", tstUsers[i].balance.decimalString(18, false));
            console.log("wFRAX after (dec'd): ", wFRAX.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(tstUsers[i].balance, _ETHBefore - 1e18, "Deposit ETH balance mismatch");
            assertEq(wFRAX.balanceOf(tstUsers[i]), _wFRAXBefore + 1e18, "Deposit wFRAX balance mismatch");

            // // Try depositing too much (should fail)
            // vm.prank(tstUsers[i]);
            // vm.expectRevert();
            // wFRAX.deposit{ value: 10_000e18 }();
        }

        // Withdraw
        console.log("============= WITHDRAW =============");
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("----- %s -----", vm.getLabel(tstUsers[i]));
            // Note balances
            uint256 _ETHBefore = tstUsers[i].balance;
            uint256 _wFRAXBefore = wFRAX.balanceOf(tstUsers[i]);
            console.log("ETH before (dec'd): ", _ETHBefore.decimalString(18, false));
            console.log("wFRAX before (dec'd): ", _wFRAXBefore.decimalString(18, false));

            // Withdraw
            vm.prank(tstUsers[i]);
            wFRAX.withdraw(1e18);

            // Check balances
            console.log("ETH after (dec'd): ", tstUsers[i].balance.decimalString(18, false));
            console.log("wFRAX after (dec'd): ", wFRAX.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(tstUsers[i].balance, _ETHBefore + 1e18, "Withdraw ETH balance mismatch");
            assertEq(wFRAX.balanceOf(tstUsers[i]), _wFRAXBefore - 1e18, "Withdraw wFRAX balance mismatch");

            // // Try withdrawing too much (should fail)
            // vm.prank(tstUsers[i]);
            // vm.expectRevert();
            // wFRAX.withdraw(10_000e18);
        }
    }
}
