// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;

contract BaseTestL2 is FraxTest, Constants.Helper {
    address public constant FRAXTAL_L1_BATCH_SENDER = 0x6017f75108f251a488B045A7ce2a7C15b179d1f2;
    address public constant FRAXTAL_L1_SEQUENCER_FEE_VAULT_RECIPIENT = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27;
    address public constant FRAXTAL_L1_OUTPUT_ORACLE_PROPOSER = 0xFb90465f3064fF63FC460F01A6307eC73d64bc50;
    address public constant FRAXTAL_L1_OUTPUT_ORACLE_CHALLENGER = 0xe0d7755252873c4eF5788f7f45764E0e17610508;

    address public constant FRAXTAL_L2_P2P_SEQUENCER = 0xc88138f5c82DD1bD327708C7F1c15E44Ce7FdA0C;
    address public constant FRAXTAL_L2_OP_PROXY_ADMIN = 0x4200000000000000000000000000000000000018;
    address public constant FRAXTAL_L2_PROXY_ADMIN = 0xfC00000000000000000000000000000000000009;
    address public constant FRAXTAL_L2_FRAXTAL_SAFE = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
    address public constant FRAXTAL_L2_SAFE_SINGLETON = 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA;
    address public constant FRAXTAL_L2_SAFE_PROXY_FACTORY = 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC;
    address public constant FRAXTAL_L2_MULTICALL = 0xcA11bde05977b3631167028862bE2a173976CA11;
    // ERC20s with owner
    address public constant FRAXTAL_L2_FRAX = 0xFc00000000000000000000000000000000000001;
    address public constant FRAXTAL_L2_SFRAX = 0xfc00000000000000000000000000000000000008;
    address public constant FRAXTAL_L2_FXS = 0xFc00000000000000000000000000000000000002;
    address public constant FRAXTAL_L2_FPI = 0xFc00000000000000000000000000000000000003;
    address public constant FRAXTAL_L2_FPIS = 0xfc00000000000000000000000000000000000004;
    address public constant FRAXTAL_L2_SFRXETH = 0xFC00000000000000000000000000000000000005;
    address public constant FRAXTAL_L2_FRXBTC = 0xfC00000000000000000000000000000000000007;
    // ERC20s without owner
    address public constant FRAXTAL_L2_WFRXETH = 0xFC00000000000000000000000000000000000006;

    function defaultSetup() public {
        uint256 BLOCK_NUMBER_L2 = vm.envOr("BLOCK_NUMBER_L2", uint256(0));
        string memory RPC_URL = vm.envString("FRAXTAL_RPC_URL");
        // Start fork from specific block if specified
        if (BLOCK_NUMBER_L2 != 0) {
            vm.createSelectFork(RPC_URL, BLOCK_NUMBER_L2);
        } else {
            vm.createSelectFork(RPC_URL);
        }
    }
}
