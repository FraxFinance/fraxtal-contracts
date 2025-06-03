// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../LiveMainnetCGTUpgradeBaseTest.t.sol";
import { IwfrxETH } from "src/contracts/Fraxtal/universal/interfaces/IwfrxETH.sol";
import { DecimalStringHelper } from "src/test/Fraxtal/helpers/DecimalStringHelper.sol";
import { SigUtils } from "src/test/Fraxtal/utils/SigUtils.sol";

contract Test_UpgradedFrxETH is LiveMainnetCGTUpgradeBaseTest {
    // using stdStorage for StdStorage;
    using DecimalStringHelper for uint256;

    // Contracts
    IwfrxETH public wfrxETH; // added for clarity
    SigUtils public sigUtilsWfrxETH;

    // Test users
    address[3] public tstUsers;
    uint256[3] public tstUserPkeys;
    address public allowanceReceiver = 0x5f4E3B89133a578E128eb3b238aa502C675cc210;
    address public permitSpender = 0x36A87d1E3200225f881488E4AEedF25303FebcAe;
    address public randomUser = 0x38c921d0e1FCB843C6d2376B5ebdE965bB523b86;

    // Before and after comparisons
    address[3] public addressesBefore;
    address[3] public addressesAfter;
    uint256[3] public allowancesBefore;
    uint256[3] public permitAllowancesBefore;
    uint256[3] public allowancesAfter;
    uint256[3] public permitAllowancesAfter;
    uint256[3] public balancesBefore;
    uint256[3] public balancesAfter;
    uint256[3] public noncesBefore;
    uint256[3] public noncesAfter;
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

        // Initialize wfrxETH
        wfrxETH = IwfrxETH(payable(address(frxETHL2)));
        sigUtilsWfrxETH = new SigUtils(wfrxETH.DOMAIN_SEPARATOR());

        // Initialize test users
        tstUserPkeys = [0xA11CE, 0xB0B, 0xc0];
        tstUsers = [payable(vm.addr(tstUserPkeys[0])), payable(vm.addr(tstUserPkeys[1])), payable(vm.addr(tstUserPkeys[2]))];

        // Label test users
        vm.label(tstUsers[0], "TU1");
        vm.label(tstUsers[1], "TU2");
        vm.label(tstUsers[2], "TU3");

        // Give test users wfrxETH
        for (uint256 i = 0; i < tstUsers.length; i++) {
            // Get ETH first
            vm.deal(tstUsers[i], 100e18);

            // Deposit some of the ETH for wfrxETH
            vm.prank(tstUsers[i]);
            wfrxETH.deposit{ value: 10e18 }();
        }

        // Set test allowances
        for (uint256 i = 0; i < tstUsers.length; i++) {
            vm.prank(tstUsers[i]);
            wfrxETH.approve(allowanceReceiver, (i + 1) * 100e18);
        }
    }

    // function etchWfrxETH() public {
    //     // Get the frxETH bytecode
    //     bytes memory _frxETHBytecode = vm.getDeployedCode("ERC20ExWrappedPPOM.sol:ERC20ExWrappedPPOM");

    //     // Note the total supply
    //     preEtchTotalSupply = address(wfrxETH).balance;

    //     // Zero out gas tokens in wfrxETH
    //     vm.deal(FRAXTAL_L2_WFRXETH, 0);

    //     // Etch the stateless code over the existing wfrxETH address
    //     vm.etch(FRAXTAL_L2_WFRXETH, _frxETHBytecode);

    //     // Write in the new name, symbol, total supply, BRIDGE, and REMOTE_TOKEN
    //     // NEED TO MASK WITH LENGTH * 2 for strings < 32 bytes
    //     // https://docs.soliditylang.org/en/v0.8.7/internals/layout_in_storage.html#bytes-and-string
    //     // https://ethereum.stackexchange.com/questions/126269/how-to-store-and-retrieve-string-which-is-more-than-32-bytesor-could-be-less-th
    //     vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(0)), bytes32("Frax Ether") | bytes32(uint256(20))); // _nameFallback and (length * 2)
    //     vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(4)), bytes32("Frax Ether") | bytes32(uint256(20))); // name and (length * 2)
    //     vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(5)), bytes32("frxETH") | bytes32(uint256(12))); // symbol and (length * 2)
    //     vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(9)), bytes32(preEtchTotalSupply));
    //     vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(15)), bytes32(uint256(uint160(Constants.FraxtalMainnet.L2_STANDARD_BRIDGE))));
    //     vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(16)), bytes32(uint256(uint160(Constants.Mainnet.FRXETH_ERC20))));

    //     // vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(15)), bytes32(bytes20(uint160(Constants.FraxtalMainnet.L2_STANDARD_BRIDGE))));
    //     // vm.store(FRAXTAL_L2_WFRXETH, bytes32(uint256(16)), bytes32(bytes20(uint160(Constants.Mainnet.FRXETH_ERC20))));

    //     // Initialize frxETH variable
    //     frxETH = ERC20ExWrappedPPOM(payable(FRAXTAL_L2_WFRXETH));

    //     // Make sure the storage got updated properly
    //     assertEq(frxETH.name(), "Frax Ether", "name not stored properly");
    //     assertEq(frxETH.symbol(), "frxETH", "symbol not stored properly");
    //     assertEq(frxETH.totalSupply(), preEtchTotalSupply, "totalSupply not stored properly");
    //     assertEq(frxETH.BRIDGE(), Constants.FraxtalMainnet.L2_STANDARD_BRIDGE, "BRIDGE not stored properly");
    //     assertEq(frxETH.REMOTE_TOKEN(), Constants.Mainnet.FRXETH_ERC20, "REMOTE_TOKEN not stored properly");

    //     // Set frxETH SigUtils
    //     sigUtils_frxETH = new SigUtils(frxETH.DOMAIN_SEPARATOR());
    // }

    function test_frxETHUpgrading() public {
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
        stringsBefore[0] = wfrxETH.name();
        stringsBefore[1] = wfrxETH.symbol();
        // stringsBefore[2] = wfrxETH.version();
        console.log("name: ", stringsBefore[0]);
        console.log("symbol: ", stringsBefore[1]);
        // console.log("version: ", stringsBefore[2]);

        // Total Supply
        totalSupplyBefore = wfrxETH.totalSupply();
        console.log("totalSupply: ", totalSupplyBefore);

        // Note balances and allowances before
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("-------- %s --------", vm.getLabel(tstUsers[i]));
            balancesBefore[i] = wfrxETH.balanceOf(tstUsers[i]);
            allowancesBefore[i] = wfrxETH.allowance(tstUsers[i], allowanceReceiver);
            noncesBefore[i] = wfrxETH.nonces(tstUsers[i]);

            console.log("Balance (dec'd): ", balancesBefore[i].decimalString(18, false));
            console.log("Allowance [normal] (dec'd): ", allowancesBefore[i].decimalString(18, false));
            console.log("Nonces: ", noncesBefore[i]);
        }

        // Upgrade
        doL2Upgrades();

        // ================================================
        // Note the state after (jank method)
        // ================================================
        console.log("============= STATE AFTER =============");

        // Switch to L2
        vm.selectFork(l2ForkID);

        // Strings
        stringsAfter[0] = frxETHL2.name();
        stringsAfter[1] = frxETHL2.symbol();
        stringsAfter[2] = frxETHL2.version();
        console.log("name: ", stringsAfter[0]);
        console.log("symbol: ", stringsAfter[1]);
        console.log("version: ", stringsAfter[2]);

        // Total Supply
        totalSupplyAfter = frxETHL2.totalSupply();
        console.log("totalSupply: ", totalSupplyAfter);
        assertEq(totalSupplyBefore, totalSupplyAfter, "totalSupply mismatch");

        // Note balances and allowances after
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("----- %s -----", vm.getLabel(tstUsers[i]));
            balancesAfter[i] = frxETHL2.balanceOf(tstUsers[i]);
            allowancesAfter[i] = frxETHL2.allowance(tstUsers[i], allowanceReceiver);
            noncesAfter[i] = frxETHL2.nonces(tstUsers[i]);

            console.log("Balance (dec'd): ", balancesAfter[i].decimalString(18, false));
            console.log("Allowance [normal] (dec'd): ", allowancesAfter[i].decimalString(18, false));
            console.log("Nonces: ", noncesBefore[i]);

            // Assert that they did not change
            assertEq(balancesBefore[i], balancesAfter[i], "Balance mismatch");
            assertEq(allowancesBefore[i], allowancesAfter[i], "Allowance mismatch");
            assertEq(noncesBefore[i], noncesAfter[i], "Nonces mismatch");

            // Check permit allowance beforehand
            permitAllowancesBefore[i] = frxETHL2.allowance(tstUsers[i], permitSpender);
            console.log("Allowance [permit, before] (dec'd): ", permitAllowancesBefore[i].decimalString(18, false));
            assertEq(permitAllowancesBefore[i], 0, "Permit allowance should be 0 beforehand");

            // Sign a test permit
            uint256 timestampToUse = block.timestamp + (1 days);
            uint256 permitNonce = frxETHL2.nonces(tstUsers[i]);
            SigUtils.Permit memory permit = SigUtils.Permit({ owner: tstUsers[i], spender: permitSpender, value: 10e18, nonce: permitNonce, deadline: timestampToUse });
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(tstUserPkeys[i], sigUtils_frxETH.getTypedDataHash(permit));
            prmDetails[i] = PermitDetails(v, r, s, timestampToUse);

            // Use the permit
            vm.prank(permitSpender);
            frxETHL2.permit(tstUsers[i], permitSpender, 10e18, prmDetails[i].timestamp, prmDetails[i].v, prmDetails[i].r, prmDetails[i].s);

            // Check permit allowance and nonce after
            permitAllowancesAfter[i] = frxETHL2.allowance(tstUsers[i], permitSpender);
            console.log("Allowance [permit, after] (dec'd): ", permitAllowancesAfter[i].decimalString(18, false));
            assertEq(permitAllowancesAfter[i], 10e18, "Permit allowance should be 10 afterwards");
            assertEq(frxETHL2.nonces(tstUsers[i]), permitNonce + 1, "Permit nonce should have increased");
        }

        // Function testing
        // deposit, withdraw, etc and some other functions should not work now...
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★ FUNCTION TESTS ★★★★★★★★★★★★★★★★★★★★★★★★");
        console.log(unicode"★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");

        // Transfer
        console.log("============= TRANSFER =============");
        for (uint256 i = 0; i < tstUsers.length; i++) {
            // Try to transfer too much (should fail)
            vm.prank(tstUsers[i]);
            vm.expectRevert();
            frxETHL2.transfer(allowanceReceiver, 100_000e18);

            // Try to transferFrom without an allowance
            vm.prank(tstUsers[i]);
            vm.expectRevert();
            frxETHL2.transferFrom(allowanceReceiver, tstUsers[i], 100_000e18);

            // Approve to the allowanceReceiver
            vm.prank(tstUsers[i]);
            frxETHL2.approve(allowanceReceiver, 1e18);

            // allowanceReceiver should be able to transferFrom, both to himself and to elsewhere.
            vm.prank(allowanceReceiver);
            frxETHL2.transferFrom(tstUsers[i], allowanceReceiver, 0.5e18);
            vm.prank(allowanceReceiver);
            frxETHL2.transferFrom(tstUsers[i], permitSpender, 0.5e18);

            // Cannot spend more than allowed
            vm.prank(allowanceReceiver);
            vm.expectRevert();
            frxETHL2.transferFrom(tstUsers[i], permitSpender, 0.5e18);
        }

        // Mint
        console.log("============= MINT =============");
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("----- %s -----", vm.getLabel(tstUsers[i]));
            // Note balances
            uint256 _frxETHBefore = frxETHL2.balanceOf(tstUsers[i]);
            console.log("frxETH before #1 (dec'd): ", _frxETHBefore.decimalString(18, false));

            // Bridge mints frxETH to test user
            vm.prank(frxETHL2.bridge());
            frxETHL2.mint(tstUsers[i], 1e18);

            // Check balances
            console.log("frxETH after #1 (dec'd): ", frxETHL2.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(frxETHL2.balanceOf(tstUsers[i]), _frxETHBefore + 1e18, "Deposit frxETH balance mismatch");

            // randomUser tries to mint (should fail)
            vm.prank(randomUser);
            vm.expectRevert();
            frxETHL2.mint(tstUsers[i], 1e18);

            // randomUser is made into a minter
            vm.prank(frxETHL2.owner());
            frxETHL2.addMinter(randomUser);

            // randomUser should be able to mint as a minter now
            _frxETHBefore = frxETHL2.balanceOf(tstUsers[i]);
            console.log("frxETH before #2 (dec'd): ", _frxETHBefore.decimalString(18, false));
            vm.prank(randomUser);
            frxETHL2.minter_mint(tstUsers[i], 1e18);
            console.log("frxETH after #2 (dec'd): ", frxETHL2.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(frxETHL2.balanceOf(tstUsers[i]), _frxETHBefore + 1e18, "Deposit frxETH balance mismatch");

            // randomUser is removed as a minter
            vm.prank(frxETHL2.owner());
            frxETHL2.removeMinter(randomUser);

            // randomUser tries to mint again (should fail)
            vm.prank(randomUser);
            vm.expectRevert();
            frxETHL2.minter_mint(tstUsers[i], 1e18);

            // randomUser is once again added as a minter
            vm.prank(frxETHL2.owner());
            frxETHL2.addMinter(randomUser);

            // randomUser should be able to mint as a minter (again) now
            _frxETHBefore = frxETHL2.balanceOf(tstUsers[i]);
            console.log("frxETH before #3 (dec'd): ", _frxETHBefore.decimalString(18, false));
            vm.prank(randomUser);
            frxETHL2.minter_mint(tstUsers[i], 1e18);
            console.log("frxETH after #3 (dec'd): ", frxETHL2.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(frxETHL2.balanceOf(tstUsers[i]), _frxETHBefore + 1e18, "Deposit frxETH balance mismatch");

            // randomUser is removed as a minter
            vm.prank(frxETHL2.owner());
            frxETHL2.removeMinter(randomUser);
        }

        // Burn
        console.log("============= BURN =============");
        for (uint256 i = 0; i < tstUsers.length; i++) {
            console.log("----- %s -----", vm.getLabel(tstUsers[i]));
            // Note balances
            uint256 _frxETHBefore = frxETHL2.balanceOf(tstUsers[i]);
            console.log("frxETH before #1 (dec'd): ", _frxETHBefore.decimalString(18, false));

            // testUser burns a token
            vm.prank(tstUsers[i]);
            frxETHL2.burn(1e18);
            console.log("frxETH after #1 (dec'd): ", frxETHL2.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(frxETHL2.balanceOf(tstUsers[i]), _frxETHBefore - 1e18, "Deposit frxETH balance mismatch");

            // randomUser tries to burn testUser token (should fail)
            vm.prank(randomUser);
            vm.expectRevert();
            frxETHL2.burnFrom(tstUsers[i], 1e18);

            // testUser approves randomUser to burn one of their tokens
            vm.prank(tstUsers[i]);
            frxETHL2.approve(randomUser, 1e18);

            // randomUser should be able to burn testUser's token now
            _frxETHBefore = frxETHL2.balanceOf(tstUsers[i]);
            vm.prank(randomUser);
            frxETHL2.burnFrom(tstUsers[i], 1e18);
            console.log("frxETH after #2 (dec'd): ", frxETHL2.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(frxETHL2.balanceOf(tstUsers[i]), _frxETHBefore - 1e18, "Deposit frxETH balance mismatch");

            // randomUser is made into a minter
            vm.prank(frxETHL2.owner());
            frxETHL2.addMinter(randomUser);

            // randomUser tries to burn testUser token, as a minter (should fail)
            vm.prank(randomUser);
            vm.expectRevert();
            frxETHL2.minter_burn_from(tstUsers[i], 1e18);

            // testUser approves randomUser to burn one of their tokens again
            vm.prank(tstUsers[i]);
            frxETHL2.approve(randomUser, 1e18);

            // randomUser tries to burn testUser token, as a minter (should work now)
            _frxETHBefore = frxETHL2.balanceOf(tstUsers[i]);
            vm.prank(randomUser);
            frxETHL2.minter_burn_from(tstUsers[i], 1e18);
            console.log("frxETH after #3 (dec'd): ", frxETHL2.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(frxETHL2.balanceOf(tstUsers[i]), _frxETHBefore - 1e18, "Deposit frxETH balance mismatch");

            // randomUser is removed as a minter
            vm.prank(frxETHL2.owner());
            frxETHL2.removeMinter(randomUser);

            // Bridge does not need approval to burn anyone's tokens
            _frxETHBefore = frxETHL2.balanceOf(tstUsers[i]);
            vm.prank(frxETHL2.bridge());
            frxETHL2.burn(tstUsers[i], 1e18);
            console.log("frxETH after #4 (dec'd): ", frxETHL2.balanceOf(tstUsers[i]).decimalString(18, false));
            assertEq(frxETHL2.balanceOf(tstUsers[i]), _frxETHBefore - 1e18, "Deposit frxETH balance mismatch");
        }
    }
}
