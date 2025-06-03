// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L1L2_InitiateDepositsAndWithdrawals is NorthStarSharedStateScript {
    bool GIVE_HELPER_CORE_TOKENS = false;
    bool TRASH_L2_GAS = false;

    // Temp vars
    uint256 _proposedOutputIndex;
    uint256 _proposedBlockNumber;
    bytes32 _stateRoot;
    bytes32 _storageRoot;
    bytes32 _outputRoot;
    bytes32 _withdrawalHash;
    uint256 _l2WithdrawalProofBlockNumber;
    bytes32 _l2WithdrawalProofBlockhash;

    bool PRINT_PWH_ADDRESSES = false;

    function setupState() internal virtual {
        super.defaultSetup();

        // The junk deployer helper and/or testerAddress may need some Eth
        if (GIVE_HELPER_CORE_TOKENS) {
            // Move to L1
            vm.selectFork(l1ForkID);

            // Start broadcasting
            vm.startBroadcast(junkDeployerPk);

            // Give the helper some L1 FRAX/frxUSD
            FRAX.transfer(junkDeployerHelperAddress, 125e18);

            // Give the helper some L1 FXS
            FXS.transfer(junkDeployerHelperAddress, 125e18);

            // Give the helper some L1 frxETH
            frxETH.transfer(junkDeployerHelperAddress, 125e18);

            // // Move to L2
            // vm.stopBroadcast();
            // vm.selectFork(l2ForkID);
            // vm.startBroadcast(junkDeployerPk);

            // // Give the helper some L2 FRAX/frxUSD

            // // Stop broadcasting
            // vm.stopBroadcast();

            // Return early
            // return;
            vm.stopBroadcast();
        }

        // Throw away gas if it is overflowing
        if (TRASH_L2_GAS) {
            // Go to L2
            vm.selectFork(l2ForkID);

            // Do the junk deployer first
            vm.startBroadcast(junkDeployerPk);

            // Throw away all but 10000 gas
            uint256 _currGas = junkDeployerAddress.balance;
            uint256 _gasToTrash = _currGas - 10_000e18;
            address(0).call{ value: _gasToTrash }("");

            // Switch to the junk deployer helper
            vm.stopBroadcast();
            vm.startBroadcast(junkDeployerHelperPk);

            // Throw away all but 10000 gas
            _currGas = junkDeployerHelperAddress.balance;
            _gasToTrash = _currGas - 10_000e18;
            address(0).call{ value: _gasToTrash }("");

            vm.stopBroadcast();
        }

        // (Optional) Print addresses for the CCMWithdrawalHelper script
        if (PRINT_PWH_ADDRESSES) {
            console.log("===================== CCMWithdrawalHelper ADDRESSES =====================");
            console.log("const l1Contracts = {");
            console.log('   AddressManager: "%s",', Constants.FraxtalL1Devnet.ADDRESS_MANAGER);
            console.log('   L1CrossDomainMessenger: "%s",', Constants.FraxtalL1Devnet.L1_CROSS_DOMAIN_MESSENGER_IMPL);
            console.log(
                '   L1CrossDomainMessengerProxy: "%s",',
                Constants.FraxtalL1Devnet.L1_CROSS_DOMAIN_MESSENGER_PROXY
            );
            console.log('   L1ERC721Bridge: "%s",', Constants.FraxtalL1Devnet.L1_ERC721_BRIDGE_IMPL);
            console.log('   L1ERC721BridgeProxy: "%s",', Constants.FraxtalL1Devnet.L1_ERC721_BRIDGE_PROXY);
            console.log('   L1StandardBridge: "%s",', Constants.FraxtalL1Devnet.L1_STANDARD_BRIDGE_IMPL);
            console.log('   L1StandardBridgeProxy: "%s",', Constants.FraxtalL1Devnet.L1_STANDARD_BRIDGE_PROXY);
            console.log('   L2OutputOracle: "%s",', Constants.FraxtalL1Devnet.L2_OUTPUT_ORACLE_IMPL);
            console.log('   L2OutputOracleProxy: "%s",', Constants.FraxtalL1Devnet.L2_OUTPUT_ORACLE_PROXY);
            console.log(
                '   OptimismMintableERC20Factory: "%s",',
                Constants.FraxtalL1Devnet.OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL
            );
            console.log(
                '   OptimismMintableERC20FactoryProxy: "%s",',
                Constants.FraxtalL1Devnet.OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY
            );
            console.log('   OptimismPortal: "%s",', Constants.FraxtalL1Devnet.OPTIMISM_PORTAL_IMPL);
            console.log('   OptimismPortalProxy: "%s",', Constants.FraxtalL1Devnet.OPTIMISM_PORTAL_PROXY);
            console.log('   ProtocolVersions: "%s",', Constants.FraxtalL1Devnet.PROTOCOL_VERSIONS_IMPL);
            console.log('   ProtocolVersionsProxy: "%s",', Constants.FraxtalL1Devnet.OPTIMISM_PORTAL_PROXY);
            console.log('   ProxyAdmin: "%s",', Constants.FraxtalL1Devnet.PROXY_ADMIN);
            console.log('   SafeProxyFactory: "%s",', Constants.FraxtalL1Devnet.SAFE_PROXY_FACTOR);
            console.log('   SafeSingleton: "%s",', Constants.FraxtalL1Devnet.SAFE_SINGLETON);
            console.log('   SuperchainConfig: "%s",', Constants.FraxtalL1Devnet.SUPERCHAIN_CONFIG_IMPL);
            console.log('   SuperchainConfigProxy: "%s",', Constants.FraxtalL1Devnet.SUPERCHAIN_CONFIG_PROXY);
            console.log('   SystemConfig: "%s",', Constants.FraxtalL1Devnet.SYSTEM_CONFIG_IMPL);
            console.log('   SystemConfigProxy: "%s",', Constants.FraxtalL1Devnet.SYSTEM_CONFIG_PROXY);
            console.log('   SystemOwnerSafe: "%s",', Constants.FraxtalL1Devnet.SYSTEM_OWNER_SAFE);
            console.log("};");
        }
    }

    // Big checklist
    // =====================
    // L1
    // -----
    // L1 FXS ERC20 -> L2 gas token
    // L1 Native ERC20 (l1Token) -> L2 Bridged/IOU ERC20 (l2Token IOU)
    // L1 Bridged/IOU ERC20 (remoteL1Token IOU) -> L2 Native ERC20 (nativeL2Token) (need to do L2 -> L1 first to get the L1 IOU tokens)
    // L1 frxETH ERC20 -> L2 frxETH ERC20

    // L2
    // -----
    // L2 Native ERC20 (nativeL2Token) -> L1 Bridged/IOU ERC20 (remoteL1Token IOU)
    // L2 Bridged/IOU ERC20 (l2Token IOU) -> L1 Native ERC20 (l1Token) (need to do L1 -> L2 first to get the L2 IOU tokens)
    // L2 gas (L2TL1MP.initiateWithdrawal) -> L1 FXS ERC20
    // L2 gas (L2TL1MP.receive) -> L1 FXS ERC20
    // L2 frxETH ERC20 -> L1 frxETH ERC20

    function run() public virtual {
        // Set up the state
        setupState();

        // ==============
        // ██       ██
        // ██      ███
        // ██       ██
        // ██       ██
        // ███████  ██
        // ==============

        // Make sure you are on L1
        vm.selectFork(l1ForkID);

        // Start broadcasting (don't use the junkDeployerPk because it is also pushing system tx's and nonces could get mixed up)
        vm.startBroadcast(junkDeployerHelperPk);
        console.log("Executing as", junkDeployerHelperAddress);

        // // Testing ground
        // {
        //     // proof for failed withdrawal: 0x1fcc1699f58df5d761f453faff0b1790df30d2539d0ffb7b21f7e466cb78d1a4
        // // failed L1 withdrawal: 0x9240b44a0d8e622e203a5e010581f05f399aab9d22deb362ff174f584ab72f81
        //     L1CrossDomainMessengerCGT(address(l1CrossDomainMessenger)).relayMessage(
        //         1766847064778384329583297500742918515827483896875618958121606201292619789,
        //         0x4200000000000000000000000000000000000007,
        //         0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690,
        //         0,
        //         492334,
        //         hex'd764ad0b000100000000000000000000000000000000000000000000000000000000000d0000000000000000000000004200000000000000000000000000000000000010000000000000000000000000e6e340d132b5f46d1e472debcd681b2abc16e57e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d4000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001040166a07a0000000000000000000000008301eb65ded23422ea8eeb64bf33d40553d32c1f000000000000000000000000fc0000000000000000000000000000000000000200000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c800000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8000000000000000000000000000000000000000000000000016345785d8a000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000003b0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
        //     );
        //     return;

        // }

        // L1 FXS ERC20 -> L2 gas token
        // L1 OptimismPortalCGT.depositERC20Transaction -> L2 (sequencer mints directly)
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1: http://127.0.0.1:3000/tx/0x48a60d88f7fcc933216978ea4447b4384c6206e06c124e2adf574f5270a5a8de
        // L2: http://127.0.0.1:40006/tx/0x3b5de659f87182d4c2a1de5e3e2fa81a3eb36c0de5133b7b8040deaa940e8a22
        if (false) {
            // Approve GAS to the OptimismPortalCGT
            FXS.approve(address(optimismPortalCGT), 0.111111e18);

            // Deposit GAS to the OptimismPortalCGT
            optimismPortalCGT.depositERC20Transaction(
                junkDeployerHelperAddress,
                0.111111e18,
                0,
                200_000,
                false,
                hex"111111"
            );
        }

        // L1 FXS ERC20 -> ??? (should fail)
        // L1 L1StandardBridge.depositERC20 -> L2 ??? (should fail - NoCGTBridgingUsePortalInstead)
        // -------------------------------------------------------------------------
        // [X] FAILS AS EXPECTED
        // L1: http://127.0.0.1:3000/tx/aaaaa
        // L2: http://127.0.0.1:40006/tx/aaaaa
        if (false) {
            // Approve GAS to the L1StandardBridge
            FXS.approve(address(l1StandardBridgeCGT), 0.222222e18);

            // Deposit GAS to the L1StandardBridge (should fail)
            // THIS SHOULD REALLY REVERT!!
            l1StandardBridgeCGT.bridgeERC20To(
                address(FXS),
                address(wFRAX),
                junkDeployerHelperAddress,
                0.222222e18,
                200_000,
                hex"222222"
            );
        }

        // L1 Native ERC20 (l1Token) -> L2 Bridged/IOU ERC20 (l2Token IOU)
        // L1 L1StandardBridge.bridgeERC20 -> L2 CrossDomainMessager (at first) -> L2 L2StandardBridge
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1: http://127.0.0.1:3000/tx/0xf5c7e005794b7a6274001f08706c07f549c5f2a6a51ab4a6685b1fece27abfa7
        // L2: http://127.0.0.1:40006/tx/0xe962721fb23ac2f2ea344bc0007bb4c00c47b676a8328286abe0cbb015a79371
        if (false) {
            // Approve L1Token to the L1StandardBridge
            l1Token.approve(address(l1StandardBridgeCGT), 0.333333e18);

            // Deposit L1Token to the L1StandardBridge
            l1StandardBridgeCGT.bridgeERC20(address(l1Token), address(l2Token), 0.333333e18, 200_000, hex"333333");
        }

        // L1 Bridged/IOU ERC20 (remoteL1Token IOU) -> L2 Native ERC20 (nativeL2Token)
        // !!! IMPORTANT: MAKE SURE TO DO L2 -> L1 FIRST OR ELSE YOU WILL REVERT FOR NOT HAVING ANY TOKENS ON L1 !!!
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1: http://127.0.0.1:3000/tx/0x4bfc95c8dea17d8083fb4e7cb4654a6a37b0bc36eac93552092b69e810b7a900
        // L2: http://127.0.0.1:40006/tx/0x80e29fdff95801d60995cd1b5e3bfc82ae820dce85ec520068967080936b4ff6
        if (false) {
            // Approve RemoteL1Token to the L1StandardBridge
            remoteL1Token.approve(address(l1StandardBridgeCGT), 0.444444e18);

            // Deposit RemoteL1Token to the L1StandardBridge
            l1StandardBridgeCGT.bridgeERC20(address(remoteL1Token), nativeL2TknAddr, 0.444444e18, 200_000, hex"444444");
        }

        // L1 frxETH ERC20 -> L2 frxETH ERC20
        // L1 L1StandardBridge.bridgeERC20 -> L2 CrossDomainMessager (at first) -> L2 L2StandardBridge
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1: http://127.0.0.1:3000/tx/0xae2e7819c41b084ad63dbca3d8885f32074bd73b5c7f3f19a788728cb6c9ddd6
        // L2: http://127.0.0.1:40006/tx/0xb9f314420792e0213e03ebd0800b67055a26fc4967bd865e6b60e8c635b5246b
        if (false) {
            // Approve L1Token to the L1StandardBridge
            frxETH.approve(address(l1StandardBridgeCGT), 0.555555e18);

            // Deposit L1Token to the L1StandardBridge
            l1StandardBridgeCGT.bridgeERC20(address(frxETH), address(frxETHL2), 0.555555e18, 200_000, hex"555555");
        }

        // ===================
        // ██      ██████
        // ██           ██
        // ██       █████
        // ██      ██
        // ███████ ███████
        // ===================

        // Move to L2
        vm.stopBroadcast();
        vm.selectFork(l2ForkID);
        vm.startBroadcast(junkDeployerHelperPk);

        // L2 Native ERC20 (nativeL2Token) -> L1 Bridged/IOU ERC20 (remoteL1Token IOU)
        // L2 l2StandardBridge.bridgeERC20To -> L1 L1StandardBridge
        // https://docs.optimism.io/stack/transactions/withdrawal-flow
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1 (prove): http://127.0.0.1:3000/tx/0xb8e6404a3f7d87ee62c609bf30215a58719208db11867692b4cec8f5fc2fd331
        // L1 (finalize): http://127.0.0.1:3000/tx/0x3b6a5ee245b762d3e7fea0fc68242349d3f1a4f2f02699b1e6e8b152fd3dfd70
        // L2: (initialize) http://127.0.0.1:40006/tx/0x064eb34891a394185a4cc67f75e20c765eae9f8502527071bab6cba1f835e689
        if (false) {
            // Initialize nonce
            // uint256 _nonce;

            // Initial
            if (false) {
                // Approve NativeL2Token to the L2StandardBridge
                nativeL2Token.approve(address(l2StandardBridge), 10.666666e18);

                // // Save this nonce
                // _nonce = l2ToL1MessagePasser.messageNonce(); // Uses Encoding.encodeVersionedNonce(_nonce, _version);
                // console.log("_nonce: ", _nonce);

                // Initiate withdrawal
                l2StandardBridge.bridgeERC20To(
                    address(nativeL2Token),
                    remoteL1TknAddr,
                    junkDeployerHelperAddress,
                    10.666666e18,
                    200_000,
                    hex"666666"
                );
            }

            // Paste the L2 tx hash for the withdrawal from above (no 0x)
            // aaaa
            // 0x71f10e76cc2314fb15c82d5e1a0102f33e9d80ad47e8454d783dbcdd5ef88f42
            // 0x8bac3c038d9c931c67df52d267c8d7d93a7adf0c39fb80c4bf8bdc3c4c2df61e
            bytes32 _withdrawalTxHashPasted = hex"064eb34891a394185a4cc67f75e20c765eae9f8502527071bab6cba1f835e689";

            // Prove Withdrawal
            if (false) {
                // Need to wait a few minutes for devnet, ~1 hr for IRL prod.
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0x71f10e76cc2314fb15c82d5e1a0102f33e9d80ad47e8454d783dbcdd5ef88f42 0 1
                ffiProveWithdrawalTx(_withdrawalTxHashPasted);
            }

            // Finalize Withdrawal
            if (true) {
                // Need to wait a minute or so
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0x71f10e76cc2314fb15c82d5e1a0102f33e9d80ad47e8454d783dbcdd5ef88f42 1 1
                ffiFinalizeWithdrawalTx(_withdrawalTxHashPasted);
            }
        }

        // L2 Bridged/IOU ERC20 (l2Token IOU) -> L1 Native ERC20 (l1Token)
        // L2 l2StandardBridge.bridgeERC20To -> L1 L1StandardBridge
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1 (prove): http://127.0.0.1:3000/tx/0x60f14fd61d9eb4d2f77ec10089790ddf47d1431253b8ddc7b89e5b3cd5d85e11
        // L1 (finalize): http://127.0.0.1:3000/tx/0x0x876875918ed44109f6695ea33b7fd16af21f71a203e82f26afb645557cc691a6
        // L2: http://127.0.0.1:40006/tx/0x0afe3bd0da6cee88dd06717232ca3ad1faf5a6568f241e2daad5b23695a2452d
        if (false) {
            // Initial
            if (false) {
                // Approve L2Token to the L2StandardBridge
                l2Token.approve(address(l2StandardBridge), 0.0777777e18);

                // Initiate withdrawal
                l2StandardBridge.bridgeERC20To(
                    address(l2Token),
                    l1TknAddr,
                    junkDeployerHelperAddress,
                    0.0777777e18,
                    200_000,
                    hex"777777"
                );
            }

            // Paste the L2 tx hash for the withdrawal from above (no 0x)
            // aaaa
            bytes32 _withdrawalTxHashPasted = hex"0afe3bd0da6cee88dd06717232ca3ad1faf5a6568f241e2daad5b23695a2452d";

            // Prove Withdrawal
            if (true) {
                // Need to wait a few minutes for devnet, ~1 hr for IRL prod.
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0x6647b76dec23faa3fda5c943554c8ca05bbb0a6ce302b208fb9218408d566284 0 1
                ffiProveWithdrawalTx(_withdrawalTxHashPasted);
            }

            // Finalize Withdrawal
            if (true) {
                // Need to wait a minute or so
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0x6647b76dec23faa3fda5c943554c8ca05bbb0a6ce302b208fb9218408d566284 1 1
                ffiFinalizeWithdrawalTx(_withdrawalTxHashPasted);
            }
        }

        // L2 gas (L2TL1MP.initiateWithdrawal) -> L1 FXS ERC20
        // L2 L2ToL1MessagePasser -> L1 OptimismPortalCGT
        // https://specs.optimism.io/experimental/custom-gas-token.html#when-an-erc20-token-is-the-native-asset
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1 (prove): http://127.0.0.1:3000/tx/0xaae11ae608acf04a6b5f3b9ce68ce6dd0d446498ab984723b78e87fba5550016
        // L1 (finalize): http://127.0.0.1:3000/tx/0x41b3fb0bbcf3d38a8485d8706f47b8a13afd9ccc10db8716f305ed9bd8d077ef
        // L2: http://127.0.0.1:40006/tx/0xef4d2912ffe839b694b62b52a1a1ff9530d18574b916a2d5cafe8c60700d5798

        if (false) {
            // Initial
            if (false) {
                // Initiate withdrawal with a direct valued call to L2ToL1MessagePasser
                // Gas limit should be >= ~200000
                l2ToL1MessagePasser.initiateWithdrawal{ value: 0.888888e18 }(
                    junkDeployerHelperAddress,
                    250_000,
                    hex"888888"
                );
            }

            // Paste the L2 tx hash for the withdrawal from above (no 0x)
            // aaaa
            bytes32 _withdrawalTxHashPasted = hex"ef4d2912ffe839b694b62b52a1a1ff9530d18574b916a2d5cafe8c60700d5798";

            // Prove Withdrawal
            if (false) {
                // Need to wait a few minutes for devnet, ~1 hr for IRL prod.
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0xbf011f444c76fcb352e1847cd51e6873fe462c04f5d1f2d1f69d25d9bc8da648 0 1
                ffiProveWithdrawalTx(_withdrawalTxHashPasted);
            }

            // Finalize Withdrawal
            if (true) {
                // Need to wait a minute or so
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0xbf011f444c76fcb352e1847cd51e6873fe462c04f5d1f2d1f69d25d9bc8da648 1 1
                ffiFinalizeWithdrawalTx(_withdrawalTxHashPasted);
            }
        }

        // L2 gas (L2TL1MP.receive) -> L1 FXS ERC20
        // L2 L2ToL1MessagePasser -> L1 OptimismPortalCGT
        // https://specs.optimism.io/experimental/custom-gas-token.html#when-an-erc20-token-is-the-native-asset
        // -------------------------------------------------------------------------
        // [X] WORKS
        // L1 (prove): http://127.0.0.1:3000/tx/0x81858783c73e0c2c4fda434e8afd6251c0ae90efebcac078d9593d12f2e6afc4
        // L1 (finalize): http://127.0.0.1:3000/tx/0x0152d05f1d29ab7ad6b91adf06b51f89e5f9930a05ac72e5afebd99a92cea28c
        // L2: http://127.0.0.1:40006/tx/0x7faf3a713e43146f7ae00db696040b2c67afbc7c5dbaa9e5814738d2325d4133

        if (false) {
            // Initial
            if (false) {
                // Initiate withdrawal with raw (receive) call to L2ToL1MessagePasser
                // Gas limit should be >= ~200000
                address(l2ToL1MessagePasser).call{ value: 0.0102030405e18 }("");
            }

            // Paste the L2 tx hash for the withdrawal from above (no 0x)
            // aaaa
            // aaaa
            // aaaa
            // aaaa
            bytes32 _withdrawalTxHashPasted = hex"7faf3a713e43146f7ae00db696040b2c67afbc7c5dbaa9e5814738d2325d4133";

            // Prove Withdrawal
            if (false) {
                // Need to wait a few minutes for devnet, ~1 hr for IRL prod.
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0xbf011f444c76fcb352e1847cd51e6873fe462c04f5d1f2d1f69d25d9bc8da648 0 1
                ffiProveWithdrawalTx(_withdrawalTxHashPasted);
            }

            // Finalize Withdrawal
            if (true) {
                // Need to wait a minute or so
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0xbf011f444c76fcb352e1847cd51e6873fe462c04f5d1f2d1f69d25d9bc8da648 1 1
                ffiFinalizeWithdrawalTx(_withdrawalTxHashPasted);
            }
        }

        // L2 frxETH ERC20 -> L1 frxETH ERC20
        // L2 L2ToL1MessagePasser -> L1 OptimismPortalCGT (should fail - NoWrappedCGTBridgingUseL2L1MsgPsrInstead)
        // -------------------------------------------------------------------------
        // [ ] FAILS AS EXPECTED
        // L1 (prove): http://127.0.0.1:3000/tx/aaaaa
        // L1 (finalize): http://127.0.0.1:3000/tx/aaaaa
        // L2: http://127.0.0.1:40006/tx/aaaaa
        if (true) {
            // Initial
            if (true) {
                // Wrap gas into wFRAX
                wFRAX.deposit{ value: 0.0999999e18 }();

                // Approve wFRAX to the bridge
                wFRAX.approve(address(l2StandardBridge), 0.0999999e18);

                // Initiate withdrawal
                l2StandardBridge.bridgeERC20To(
                    address(wFRAX),
                    address(FXS),
                    junkDeployerHelperAddress,
                    0.0999999e18,
                    200_000,
                    hex"999999"
                );
            }

            // Paste the L2 tx hash for the withdrawal from above (no 0x)
            // aaaa
            bytes32 _withdrawalTxHashPasted = hex"6647b76dec23faa3fda5c943554c8ca05bbb0a6ce302b208fb9218408d566284";

            // Prove Withdrawal
            if (false) {
                // Need to wait a few minutes for devnet, ~1 hr for IRL prod.
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0x6647b76dec23faa3fda5c943554c8ca05bbb0a6ce302b208fb9218408d566284 0 1
                ffiProveWithdrawalTx(_withdrawalTxHashPasted);
            }

            // Finalize Withdrawal
            if (false) {
                // Need to wait a minute or so
                // node scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js 0x6647b76dec23faa3fda5c943554c8ca05bbb0a6ce302b208fb9218408d566284 1 1
                ffiFinalizeWithdrawalTx(_withdrawalTxHashPasted);
            }
        }
    }
}
