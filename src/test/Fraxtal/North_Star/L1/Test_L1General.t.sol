// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../LiveMainnetCGTUpgradeBaseTest.t.sol";
import { IwfrxETH } from "src/contracts/Fraxtal/universal/interfaces/IwfrxETH.sol";
import { DecimalStringHelper } from "src/test/Fraxtal/helpers/DecimalStringHelper.sol";
import { SigUtils } from "src/test/Fraxtal/utils/SigUtils.sol";

contract Test_L1General is LiveMainnetCGTUpgradeBaseTest {
    // using stdStorage for StdStorage;
    using DecimalStringHelper for uint256;

    // Test users
    address[3] public tstUsers;
    uint256[3] public tstUserPkeys;
    address public allowanceReceiver = 0x5f4E3B89133a578E128eb3b238aa502C675cc210;
    address public permitSpender = 0x36A87d1E3200225f881488E4AEedF25303FebcAe;
    address public randomUser = 0x38c921d0e1FCB843C6d2376B5ebdE965bB523b86;

    bool public USING_DEVNET = true;

    function setUp() public {
        // Set everything up but don't do upgrades yet
        defaultSetup();

        // Switch to L1
        vm.selectFork(l1ForkID);

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
            vm.deal(tstUsers[i], 1e18);
        }
    }

    function test_L1Upgrades() public {
        setUp();

        // // Print SystemConfig Info
        // printSystemConfigInfo();

        // return;

        // Do the L1 upgrades
        doL1Upgrades();
    }
}
