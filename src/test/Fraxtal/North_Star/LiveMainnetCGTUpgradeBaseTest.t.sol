// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "src/script/Fraxtal/North_Star_Hardfork/NorthStarSharedStateScript.s.sol";

contract LiveMainnetCGTUpgradeBaseTest is NorthStarSharedStateScript {
    function defaultSetup() internal override {
        super.defaultSetup();
    }

    function doL2Upgrades() public {
        // ================================================
        // Start upgrading the L2 contracts
        // ================================================
        // Check the starting versions of the L2 tokens
        checkStartingL2Versions();

        // // Get implementation
        // vm.startPrank(address(0));
        // // console.log("wFRAX proxy admin: ", l2ProxyAdminCore8.getProxyAdmin(payable(address(wFRAX))));
        // // console.log("wFRAX old implementation: ", l2ProxyAdminCore8.getProxyImplementation(payable(address(wFRAX))));

        // // console.log("l2ProxyAdminCore8 implementation: ", l2ProxyAdminCore8.getProxyAdmin(payable(address(wFRAX))));
        // // console.log("wFRAX old implementation: ", l2ProxyAdminCore8.getProxyImplementation(payable(address(wFRAX))));

        // vm.stopPrank();
        // return;

        // // Get implementation
        // vm.startPrank(address(l2Safe));
        // // l2ProxyAdminRsvd10K.changeProxyAdmin(payable(address(wFRAX)), address(l2ProxyAdminCore8));
        // // l2ProxyAdminCore8.getProxyAdmin(payable(address(wFRAX)));
        // // l2ProxyAdminRsvd10K.changeProxyAdmin(payable(address(wFRAX)), address(l2ProxyAdminCore8));

        // vm.stopPrank();
        // return;

        // Do the upgrades
        // !!!!!! IMPORTANT !!!!!!
        // !!!!!! IMPORTANT !!!!!!
        // !!!!!! IMPORTANT !!!!!!
        // https://specs.optimism.io/experimental/custom-gas-token.html#upgrade
        // The deployment transactions MUST have a from value that has no code and has no known private key. This is to guarantee it cannot be frontrun and have its nonce modified. If this was possible, then an attacker would be able to modify the address that the implementation is deployed to because it is based on CREATE and not CREATE2. This would then cause the proxy implementation set transactions to set an incorrect implementation address, resulting in a bricked contract. The calldata is not generated dynamically to enable deterministic upgrade transactions across all networks.
        // The proxy upgrade transactions are from address(0) because the Proxy implementation considers address(0) to be an admin. Going straight to the Proxy guarantees that the upgrade will work because there is no guarantee that the Proxy is owned by the ProxyAdmin and going through the ProxyAdmin would require stealing the identity of its owner, which may be different on every chain. That would require adding L2 RPC access to the derivation pipeline and make the upgrade transactions non deterministic.
        // DOUBLE CHECK TO SEE IF THIS IS ACTUALLY RELEVANT HERE
        // DOUBLE CHECK TO SEE IF THIS IS ACTUALLY RELEVANT HERE
        // DOUBLE CHECK TO SEE IF THIS IS ACTUALLY RELEVANT HERE
        // DOUBLE CHECK TO SEE IF THIS IS ACTUALLY RELEVANT HERE
        // !!!!!! IMPORTANT !!!!!!
        // !!!!!! IMPORTANT !!!!!!
        // !!!!!! IMPORTANT !!!!!!

        deployL2_StorageSetterRestricted();
        upgradeL2_FeeVaults();
        upgradeL2_L1BlockCGT();
        upgradeL2_L2CrossDomainMessengerCGT();
        upgradeL2_L2StandardBridgeCGT();
        upgradeL2_FxsToWFrax();
        upgradeL2_WfrxEthToFrxEth();

        // Check the ending versions of the L2 contracts
        checkEndingL2Versions();
    }

    function doL1Upgrades() public {
        // ================================================
        // Start upgrading the L1 contracts
        // ================================================
        // Switch back to L1
        vm.selectFork(l1ForkID);

        // Check the starting versions of the L1 contracts
        checkStartingL1Versions();

        // Do the upgrades
        deployL1_StorageSetterRestricted();
        upgradeL1_OptimismPortalCGT();
        upgradeL1_SystemConfigCGT();
        upgradeL1_L1CrossDomainMessengerCGT();
        upgradeL1_L1StandardBridgeCGT();
        upgradeL1_L1ERC721Bridge();
        // upgradeL1_L2OutputOracle();
        upgradeL1_OptimismMintableERC20Factory();
        // upgradeL1_ProtocolVersions();
        // upgradeL1_SuperchainConfig();

        // Check the ending versions of the L1 contracts
        checkEndingL1Versions();
    }

    function doUpgrades() public {
        doL2Upgrades();
        doL1Upgrades();
    }

    function checkStartingL2Versions() public {
        string memory _tmpVersion = baseFeeVaultCGT.version();
        if (!(compareStrings(_tmpVersion, "1.4.1") || compareStrings(_tmpVersion, "1.5.0-beta.3"))) revert("Wrong Start L2 BaseFeeVault version");
        _tmpVersion = l1FeeVaultCGT.version();
        if (!(compareStrings(_tmpVersion, "1.4.1") || compareStrings(_tmpVersion, "1.5.0-beta.3"))) revert("Wrong Start L2 L1FeeVault version");
        _tmpVersion = sequencerFeeVaultCGT.version();
        if (!(compareStrings(_tmpVersion, "1.4.1") || compareStrings(_tmpVersion, "1.5.0-beta.3"))) revert("Wrong Start L2 SequencerFeeVault version");
        _tmpVersion = l1Block.version();
        if (!(compareStrings(_tmpVersion, "1.2.0") || compareStrings(_tmpVersion, "1.5.1-beta.3"))) revert("Wrong Start L2 L1Block version");
        // _tmpVersion = l2StandardBridge.version();
        // if (!(compareStrings(_tmpVersion, abcxxx ? "1.8.0" : "1.7.0") || compareStrings(_tmpVersion, "1.11.1-beta.3"))) revert("Wrong Start L2 L2StandardBridge version");
        // _tmpVersion = l2CrossDomainMessenger.version();
        // if (!(compareStrings(_tmpVersion, abcxxx ? "2.0.0" : "1.8.0") || compareStrings(_tmpVersion, "2.1.1-beta.4"))) revert("Wrong Start L2 L2CrossDomainMessager version");
        _tmpVersion = wFRAX.version();
        if (!(compareStrings(_tmpVersion, "1.0.0") || compareStrings(_tmpVersion, "1.0.1"))) revert("Wrong Start L2 wFRAX version");

        // vm.expectRevert(); // frxETHL2 doesn't have version() yet
        // frxETHL2.version();
        // assertEq(AAAAAA(address(BBBBBB)).version(), "XXXXXX", "Wrong Start L2 AAAAAA version");
    }

    function checkEndingL2Versions() public {
        assertEq(baseFeeVaultCGT.version(), "1.5.0-beta.3", "Wrong End L2 BaseFeeVaultCGT version");
        assertEq(l1FeeVaultCGT.version(), "1.5.0-beta.3", "Wrong End L2 L1FeeVaultCGT version");
        assertEq(sequencerFeeVaultCGT.version(), "1.5.0-beta.3", "Wrong End L2 SequencerFeeVaultCGT version");
        assertEq(l1Block.version(), "1.5.1-beta.3", "Wrong End L2 L1BlockCGT version");
        assertEq(l2StandardBridge.version(), "1.11.1-beta.3", "Wrong End L2 L2StandardBridgeCGT version");
        assertEq(l2CrossDomainMessenger.version(), "2.1.1-beta.4", "Wrong End L2 L2CrossDomainMessagerCGT version");
        assertEq(wFRAX.version(), "1.0.1", "Wrong End L2 wFRAX version");
        assertEq(frxETHL2.version(), "1.0.0", "Wrong End L2 frxETHL2 version");
        // assertEq(AAAAAA(address(BBBBBB)).version(), "XXXXXX", "Wrong End L2 AAAAAA version");
    }

    // ===================================================================================
    // ██      ██████      ██    ██ ██████   ██████  ██████   █████  ██████  ███████ ███████
    // ██           ██     ██    ██ ██   ██ ██       ██   ██ ██   ██ ██   ██ ██      ██
    // ██       █████      ██    ██ ██████  ██   ███ ██████  ███████ ██   ██ █████   ███████
    // ██      ██          ██    ██ ██      ██    ██ ██   ██ ██   ██ ██   ██ ██           ██
    // ███████ ███████      ██████  ██       ██████  ██   ██ ██   ██ ██████  ███████ ███████
    // ===================================================================================
    // https://patorjk.com/software/taag/#p=display&f=ANSI%20Regular&t=L2%20UPGRADES

    function deployL2_StorageSetterRestricted() public {
        if (address(storageSetterL2) == address(0)) storageSetterL2 = new StorageSetterRestricted();
    }

    function upgradeL2_FeeVaults() public {
        // Become the proxy admin owner
        vm.startPrank(l2ProxyAdminOpSysOwner);

        // Upgrade BaseFeeVault to BaseFeeVaultCGT
        // ============================================
        console.log("\n========== BaseFeeVaultCGT ==========");
        console.log("Upgrade BaseFeeVault to BaseFeeVaultCGT");

        // Deploy the impl for BaseFeeVaultCGT
        baseFeeVaultCGT_Impl = new BaseFeeVaultCGT();

        // Prepare initialization call
        bytes memory data = abi.encodeCall(baseFeeVaultCGT_Impl.initialize, (l2SafeAddress, 1 ether, Types.WithdrawalNetwork.L2));

        // Upgrade the BaseFeeVault Proxy to use the BaseFeeVaultCGT implementation
        l2ProxyAdminOpSys.upgradeAndCall(payable(address(baseFeeVaultCGT)), address(baseFeeVaultCGT_Impl), data);

        // Upgrade L1FeeVault to L1FeeVaultCGT
        // ============================================
        console.log("\n========== L1FeeVaultCGT ==========");
        console.log("Upgrade L1FeeVault to L1FeeVaultCGT");

        // Deploy the impl for L1FeeVaultCGT
        l1FeeVaultCGT_Impl = new L1FeeVaultCGT();

        // Prepare initialization call
        data = abi.encodeCall(l1FeeVaultCGT_Impl.initialize, (l2SafeAddress, 1 ether, Types.WithdrawalNetwork.L2));

        // Upgrade the BaseFeeVault Proxy to use the L1FeeVaultCGT implementation
        l2ProxyAdminOpSys.upgradeAndCall(payable(address(l1FeeVaultCGT)), address(l1FeeVaultCGT_Impl), data);

        // Upgrade SequencerFeeVault to SequencerFeeVaultCGT
        // ============================================
        console.log("\n========== BaseFeeVaultCGT ==========");
        console.log("Upgrade SequencerFeeVault to SequencerFeeVaultCGT");

        // Deploy the impl for SequencerFeeVaultCGT
        sequencerFeeVaultCGT_Impl = new SequencerFeeVaultCGT();

        // Prepare initialization call
        data = abi.encodeCall(sequencerFeeVaultCGT_Impl.initialize, (l2SafeAddress, 1 ether, Types.WithdrawalNetwork.L2));

        // Upgrade the BaseFeeVault Proxy to use the SequencerFeeVaultCGT implementation
        l2ProxyAdminOpSys.upgradeAndCall(payable(address(sequencerFeeVaultCGT)), address(sequencerFeeVaultCGT_Impl), data);

        vm.stopPrank();
    }

    function upgradeL2_L1BlockCGT() public {
        // Upgrade FraxchainL1Block to L1BlockCGT
        // ============================================
        console.log("\n========== L1BlockCGT ==========");
        console.log("Upgrade FraxchainL1Block to L1BlockCGT");

        // Become the proxy admin owner
        vm.startPrank(l2ProxyAdminOpSysOwner);

        // Deploy the impl for L1BlockCGT
        L1BlockCGT theImpl = new L1BlockCGT();

        // ProxyAdmin upgrade (no initialize())
        l2ProxyAdminOpSys.upgrade(payable(address(l1Block)), address(theImpl));

        vm.stopPrank();
    }

    function upgradeL2_L2CrossDomainMessengerCGT() public {
        // Upgrade L2StandardBridge to L2CrossDomainMessengerCGT
        // ============================================
        console.log("\n========== L2CrossDomainMessengerCGT ==========");
        console.log("Upgrade L2CrossDomainMessenger to L2CrossDomainMessengerCGT");

        // Check
        if (address(storageSetterL2) == address(0)) revert("Need to deploy StorageSetterRestricted and the other Impls");

        // Become the proxy admin owner
        vm.startPrank(l2ProxyAdminOpSysOwner);

        // Deploy the impl for L2CrossDomainMessengerCGT
        L2CrossDomainMessengerCGT theImpl = new L2CrossDomainMessengerCGT();

        // ProxyAdmin upgradeToAndCall route
        {
            // Upgrade and clear initialization
            l2ProxyAdminOpSys.upgradeAndCall(payable(address(l2CrossDomainMessenger)), address(storageSetterL2), abi.encodeWithSignature("clearSlotZero()"));

            uint256 initializedValue = StorageSetterRestricted(address(l2CrossDomainMessenger)).getUint(0);
            console.log("Cleared L2CrossDomainMessengerCGT initialized flag, new value", initializedValue);

            // Prepare initialization call
            bytes memory data = abi.encodeCall(theImpl.initialize, (CrossDomainMessenger(l1CrossDomainMessengerAddress)));

            // Upgrade the L2StandardBridge Proxy to use the L2CrossDomainMessengerCGT implementation
            l2ProxyAdminOpSys.upgradeAndCall(payable(address(l2CrossDomainMessenger)), address(theImpl), data);
        }

        vm.stopPrank();
    }

    function upgradeL2_L2StandardBridgeCGT() public {
        // Upgrade L2StandardBridge to L2StandardBridgeCGT
        // ============================================
        console.log("\n========== L2StandardBridgeCGT ==========");
        console.log("Upgrade L2StandardBridge to L2StandardBridgeCGT");

        // Become the proxy admin owner
        vm.startPrank(l2ProxyAdminOpSysOwner);

        // Deploy the impl for L2StandardBridgeCGT
        L2StandardBridgeCGT theImpl = new L2StandardBridgeCGT();

        // ProxyAdmin upgradeToAndCall route
        {
            // Upgrade and clear initialization
            l2ProxyAdminOpSys.upgradeAndCall(payable(address(l2StandardBridge)), address(storageSetterL2), abi.encodeWithSignature("clearSlotZero()"));

            uint256 initializedValue = StorageSetterRestricted(address(l2StandardBridge)).getUint(0);
            console.log("Cleared L2StandardBridgeCGT initialized flag, new value", initializedValue);

            // Prepare initialization call
            bytes memory data = abi.encodeCall(theImpl.initialize, (StandardBridge(l1StdBridgePxyAddress)));

            // Upgrade the L2StandardBridge Proxy to use the L2StandardBridgeCGT implementation
            l2ProxyAdminOpSys.upgradeAndCall(payable(address(l2StandardBridge)), address(theImpl), data);
        }

        vm.stopPrank();
    }

    function upgradeL2_FxsToWFrax() public {
        // NOTE: BEFORE THE MAIN HARD FORK, THERE WILL BE A PROXY HERE INSTEAD
        // NOTE: BEFORE THE MAIN HARD FORK, THERE WILL BE A PROXY HERE INSTEAD
        // NOTE: BEFORE THE MAIN HARD FORK, THERE WILL BE A PROXY HERE INSTEAD

        console.log("\n========== wFRAX ==========");
        console.log("Upgrade FXS to wFRAX");

        // Note the total supply beforehand
        uint256 _tSupply = wFRAX.totalSupply();
        console.log("wFRAX.totalSupply() (before): ", _tSupply);

        // Dump _tSupply gas tokens (ETH here, for now) into wFRAX
        vm.deal(address(wFRAX), _tSupply);

        // // Etch / deploy a proxy to the wFRAX address first
        // deployCodeTo("Proxy.sol:Proxy", abi.encode(address(l2ProxyAdminCore8)), address(wFRAX));

        // Get implementation
        console.log("wFRAX proxy admin: ", payable(l2ProxyAdminCore8.getProxyAdmin(payable(address(wFRAX)))));
        console.log("wFRAX proxy admin's owner: ", ProxyAdmin(l2ProxyAdminCore8.getProxyAdmin(payable(address(wFRAX)))).owner());
        console.log("wFRAX old implementation: ", l2ProxyAdminCore8.getProxyImplementation(payable(address(wFRAX))));

        // Deploy the wFRAX implementation
        // Have to do this instead of new to avoid version mismatches
        // https://ethereum.stackexchange.com/questions/153940/how-to-resolve-compiler-version-conflicts-in-foundry-test-contracts
        wFRAX_Impl = IERC20ExPPOMWrapped(payable(deployCode("ERC20ExPPOMWrapped.sol:ERC20ExPPOMWrapped")));

        // Prepare initialization call
        bytes memory data = abi.encodeCall(wFRAX_Impl.initialize, ("Wrapped Frax", "wFRAX", "1.0.1"));

        // Become the ProxyAdmin owner
        vm.startPrank(l2ProxyAdminCore8Owner);

        // Upgrade the wFRAX Proxy to use the ERC20ExPPOMWrapped implementation
        l2ProxyAdminCore8.upgradeAndCall(payable(address(wFRAX)), address(wFRAX_Impl), data);

        // Make sure the storage got updated properly
        assertEq(wFRAX.name(), "Wrapped Frax", "name not stored properly");
        assertEq(wFRAX.symbol(), "wFRAX", "symbol not stored properly");

        // Reset wFRAX SigUtils
        sigUtils_wFRAX = new SigUtils(wFRAX.DOMAIN_SEPARATOR());
        vm.makePersistent(address(sigUtils_wFRAX));
        vm.label(address(sigUtils_wFRAX), "sigUtils_wFRAX");
        console.log("sigUtils_wFRAX deployed to: ", address(sigUtils_wFRAX));

        vm.stopPrank();
    }

    function upgradeL2_WfrxEthToFrxEth() public {
        // NOTE: BEFORE THE MAIN HARD FORK, THERE WILL BE A PROXY HERE INSTEAD, SO YOU WILL HAVE TO STORAGESETTER IT
        // NOTE: BEFORE THE MAIN HARD FORK, THERE WILL BE A PROXY HERE INSTEAD, SO YOU WILL HAVE TO STORAGESETTER IT
        // NOTE: BEFORE THE MAIN HARD FORK, THERE WILL BE A PROXY HERE INSTEAD, SO YOU WILL HAVE TO STORAGESETTER IT

        console.log("\n========== frxETH ==========");
        console.log("Upgrade wfrxETH to frxETH");

        // Note the total supply
        preEtchTotalSupply = address(frxETHL2).balance;
        console.log("address(frxETHL2).balance (before): ", preEtchTotalSupply);

        // // Etch / deploy a proxy to the frxETH address first
        // deployCodeTo("Proxy.sol:Proxy", abi.encode(address(l2ProxyAdminCore8)), address(frxETHL2));

        // Deploy the frxETHL2 implementation
        // Have to do this instead of new to avoid version mismatches
        // https://ethereum.stackexchange.com/questions/153940/how-to-resolve-compiler-version-conflicts-in-foundry-test-contracts
        frxETHL2_Impl = IERC20ExWrappedPPOM(payable(deployCode("ERC20ExWrappedPPOM.sol:ERC20ExWrappedPPOM")));

        // Prepare initialization call
        bytes memory data = abi.encodeCall(frxETHL2_Impl.initialize, (l2ProxyAdminCore8Owner, l2ProxyAdminCore8Owner, Constants.FraxtalMainnet.L2_STANDARD_BRIDGE, address(frxETH), preEtchTotalSupply, "Frax Ether", "frxETH", "1.0.0"));

        // Become the ProxyAdmin owner
        vm.startPrank(l2ProxyAdminCore8Owner);

        // Upgrade the frxETHL2 Proxy to use the ERC20ExWrappedPPOM implementation
        l2ProxyAdminCore8.upgradeAndCall(payable(address(frxETHL2)), address(frxETHL2_Impl), data);

        // Zero out gas tokens in wfrxETH
        vm.deal(address(frxETHL2), 0);

        // Make sure the storage got updated properly
        assertEq(frxETHL2.name(), "Frax Ether", "name not stored properly");
        assertEq(frxETHL2.symbol(), "frxETH", "symbol not stored properly");
        assertEq(frxETHL2.totalSupply(), preEtchTotalSupply, "totalSupply not stored properly");
        assertEq(frxETHL2.BRIDGE(), Constants.FraxtalMainnet.L2_STANDARD_BRIDGE, "BRIDGE not stored properly");
        assertEq(frxETHL2.REMOTE_TOKEN(), address(frxETH), "REMOTE_TOKEN not stored properly");

        // Reset frxETH SigUtils
        sigUtils_frxETH = new SigUtils(frxETHL2.DOMAIN_SEPARATOR());
        vm.makePersistent(address(sigUtils_frxETH));
        vm.label(address(sigUtils_frxETH), "sigUtils_frxETH");

        vm.stopPrank();
    }

    // ===================================================================================
    // ██       ██     ██    ██ ██████   ██████  ██████   █████  ██████  ███████ ███████
    // ██      ███     ██    ██ ██   ██ ██       ██   ██ ██   ██ ██   ██ ██      ██
    // ██       ██     ██    ██ ██████  ██   ███ ██████  ███████ ██   ██ █████   ███████
    // ██       ██     ██    ██ ██      ██    ██ ██   ██ ██   ██ ██   ██ ██           ██
    // ███████  ██      ██████  ██       ██████  ██   ██ ██   ██ ██████  ███████ ███████
    // ===================================================================================
    // https://patorjk.com/software/taag/#p=display&f=ANSI%20Regular&t=L1%20UPGRADES

    function checkStartingL1Versions() public {
        assertEq(L1CrossDomainMessenger(address(l1CrossDomainMessenger)).version(), "2.3.0", "Wrong Start L1 L1CrossDomainMessenger version");
        assertEq(L1ERC721Bridge(address(l1Erc721Bridge)).version(), "2.1.0", "Wrong Start L1 L1ERC721Bridge version");
        assertEq(L1StandardBridge(l1StdBridgePxyAddress).version(), "2.1.0", "Wrong Start L1 L1StandardBridge version");
        assertEq(L2OutputOracle(address(l2OutputOracle)).version(), "1.8.0", "Wrong Start L1 L2OutputOracle version");
        assertEq(OptimismMintableERC20Factory(address(l1OptimismMintableERC20Factory)).version(), "1.9.0", "Wrong Start L1 OptimismMintableERC20Factory version");
        assertEq(OptimismPortal(optimismPortalPxyAddress).version(), "2.5.0", "Wrong Start L1 OptimismPortal version");
        assertEq(ProtocolVersions(address(protocolVersions)).version(), "1.0.0", "Wrong Start L1 ProtocolVersions version");
        assertEq(ISuperchainConfig(address(superchainConfig)).version(), "1.1.0", "Wrong Start L1 SuperchainConfig version");
        assertEq(ISystemConfig(address(systemConfig)).version(), "1.12.0", "Wrong Start L1 SystemConfig version");
        // assertEq(AAAAAA(address(BBBBBB)).version(), "XXXXXX", "Wrong Start L1 AAAAAA version");
    }

    function checkEndingL1Versions() public {
        assertEq(L1CrossDomainMessengerCGT(address(l1CrossDomainMessenger)).version(), "2.4.1-beta.2", "Wrong End L1 L1CrossDomainMessengerCGT version");
        assertEq(L1ERC721Bridge(address(l1Erc721Bridge)).version(), "2.2.0-beta.1", "Wrong End L1 L1ERC721Bridge version");
        assertEq(L1StandardBridgeCGT(l1StdBridgePxyAddress).version(), "2.2.1-beta.2", "Wrong End L1 L1StandardBridgeCGT version");
        // assertEq(L2OutputOracle(address(l2OutputOracle)).version(), "1.8.0", "Wrong End L1 L2OutputOracle version");
        assertEq(OptimismMintableERC20Factory(address(l1OptimismMintableERC20Factory)).version(), "1.10.1-beta.4", "Wrong End L1 OptimismMintableERC20Factory version");
        assertEq(OptimismPortalCGT(optimismPortalPxyAddress).version(), "2.8.1-beta.4", "Wrong End L1 OptimismPortalCGT version");
        // assertEq(ProtocolVersions(address(protocolVersions)).version(), "1.0.0", "Wrong End L1 ProtocolVersions version");
        // assertEq(ISuperchainConfig(address(superchainConfig)).version(), "1.1.0", "Wrong End L1 SuperchainConfig version");
        assertEq(ISystemConfig(address(systemConfig)).version(), "2.3.0", "Wrong End L1 SystemConfigCGT version");
        // assertEq(AAAAAA(address(BBBBBB)).version(), "XXXXXX", "Wrong End L1 AAAAAA version");
    }

    function deployL1_StorageSetterRestricted() public {
        if (address(storageSetterL1) == address(0)) storageSetterL1 = new StorageSetterRestricted();
    }

    function upgradeL1_OptimismPortalCGT() public {
        // Upgrade OptimismPortal to OptimismPortalCGT
        // ============================================
        console.log("\n========== OptimismPortalCGT ==========");
        console.log("Upgrade OptimismPortal to OptimismPortalCGT");

        // console.log("l1ProxyAdminOwner: ", l1ProxyAdminOwner);
        // hoax(address(0));
        // console.log("l1ProxyAdmin.owner(): ", l1ProxyAdmin.owner());

        // Become the proxy admin owner
        vm.startPrank(l1ProxyAdminOwner);

        // Deploy the impl for OptimismPortalCGT
        OptimismPortalCGT opPortalCGTImpl = new OptimismPortalCGT();

        // ProxyAdmin upgradeToAndCall route
        {
            // Practice at least once using the proper Gnosis safe route instead of hoax()
            if (false) {
                // Upgrade and clear initialization
                // ----------------------------------
                // Get the calldata
                bytes memory _theCalldata = abi.encodeWithSelector(ProxyAdmin.upgradeAndCall.selector, optimismPortalPxyAddress, address(storageSetterL1), abi.encodeWithSignature("clearSlotZero()"));

                // Stop being the proxy admin owner
                vm.stopPrank();

                // Execute the initialization clearing
                approveAndExecSafeTx(address(l1ProxyAdmin), _theCalldata);

                // Become the proxy admin owner again
                vm.startPrank(l1ProxyAdminOwner);

                revert("MANUAL REVERT");

                // Prepare initialization call
                // ----------------------------------
                bytes memory data = abi.encodeCall(opPortalCGTImpl.initialize, (IL2OutputOracle(address(l2OutputOracle)), ISystemConfig(address(systemConfig)), ISuperchainConfig(address(superchainConfig)), address(frxETH), payable(l1SafeAddress)));

                // Upgrade the OptimismPortal Proxy to use the FraxtalPortal2 implementation
                l1ProxyAdmin.upgradeAndCall(optimismPortalPxyAddress, address(opPortalCGTImpl), data);
            } else {
                // Upgrade and clear initialization
                // ----------------------------------
                l1ProxyAdmin.upgradeAndCall(optimismPortalPxyAddress, address(storageSetterL1), abi.encodeWithSignature("clearSlotZero()"));

                uint256 initializedValue = StorageSetterRestricted(address(optimismPortalPxyAddress)).getUint(0);
                console.log("Cleared OptimismPortal initialized flag, new value", initializedValue);

                // Prepare initialization call
                // ----------------------------------
                bytes memory data = abi.encodeCall(opPortalCGTImpl.initialize, (IL2OutputOracle(address(l2OutputOracle)), ISystemConfig(address(systemConfig)), ISuperchainConfig(address(superchainConfig)), address(frxETH), payable(l1SafeAddress)));

                // Upgrade the OptimismPortal Proxy to use the FraxtalPortal2 implementation
                l1ProxyAdmin.upgradeAndCall(optimismPortalPxyAddress, address(opPortalCGTImpl), data);
            }
        }

        vm.stopPrank();
    }

    function upgradeL1_SystemConfigCGT() public {
        // Upgrade SystemConfig to SystemConfigCGT
        // ============================================
        console.log("\n========== SystemConfigCGT ==========");
        console.log("Upgrade SystemConfig to SystemConfigCGT");

        vm.startPrank(systemConfigUpgradeCaller);

        console.log("Executing as", systemConfigUpgradeCaller);

        string memory version = systemConfig.version();
        console.log("Systemconfig version:", version);

        address owner = systemConfig.owner();
        console.log("Systemconfig owner:", owner);

        basefeeScalar = 0; // Can update later
        console.log("Systemconfig basefeeScalar:", basefeeScalar);

        blobbasefeeScalar = 0; // Can update later
        console.log("Systemconfig blobbasefeeScalar:", blobbasefeeScalar);

        batcherHash = systemConfig.batcherHash();
        // console.log("Systemconfig batcherHash:", uint256(batcherHash));
        console.log("------- Systemconfig batcherHash -------");
        console.logBytes32(systemConfig.batcherHash());

        gasLimit = systemConfig.gasLimit();
        console.log("Systemconfig gasLimit:", gasLimit);

        unsafeBlockSigner = systemConfig.unsafeBlockSigner();
        console.log("Systemconfig unsafeBlockSigner:", unsafeBlockSigner);

        IResourceMetering.ResourceConfig memory resourceConfig = systemConfig.resourceConfig();
        console.log("Systemconfig resourceConfig elasticityMultiplier", resourceConfig.elasticityMultiplier);

        batchInbox = systemConfig.batchInbox();
        console.log("Systemconfig batchInbox:", batchInbox);

        // (address gasTokenAddr, ) = systemConfig.gasPayingToken();
        gasTokenAddr = address(FXS);
        SystemConfigCGT.Addresses memory addresses = SystemConfigCGT.Addresses({
            l1CrossDomainMessenger: address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_CROSS_DOMAIN_MESSENGER_SLOT())))),
            l1ERC721Bridge: address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_ERC_721_BRIDGE_SLOT())))),
            l1StandardBridge: address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_STANDARD_BRIDGE_SLOT())))),
            l2OutputOracle: address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L2_OUTPUT_ORACLE_SLOT())))),
            disputeGameFactory: address(0), // Leave 0 for now?
            optimismPortal: address(uint160(uint256(vm.load(address(systemConfig), systemConfig.OPTIMISM_PORTAL_SLOT())))),
            optimismMintableERC20Factory: address(uint160(uint256(vm.load(address(systemConfig), systemConfig.OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT())))),
            gasPayingToken: gasTokenAddr
        });

        console.log("Systemconfig addresses l1CrossDomainMessenger:", addresses.l1CrossDomainMessenger);
        console.log("Systemconfig addresses l1ERC721Bridge:", addresses.l1ERC721Bridge);
        console.log("Systemconfig addresses l2OutputOracle:", addresses.l2OutputOracle);
        console.log("Systemconfig addresses l1StandardBridge:", addresses.l1StandardBridge);
        console.log("Systemconfig addresses disputeGameFactory:", addresses.disputeGameFactory);
        console.log("Systemconfig addresses optimismPortal:", addresses.optimismPortal);
        console.log("Systemconfig addresses optimismMintableERC20Factory:", addresses.optimismMintableERC20Factory);
        console.log("Systemconfig addresses gasPayingToken:", addresses.gasPayingToken);

        systemConfigImplementationAddr = l1ProxyAdmin.getProxyImplementation(address(systemConfig));
        console.log("Current SystemConfig implementation address", systemConfigImplementationAddr);

        // Deploy the impl for the new SystemConfigCGT
        systemConfigImplementationAddr = address(new SystemConfigCGT());
        console.log("New SystemConfigCGT implementation address", systemConfigImplementationAddr);

        // Upgrade and clear initialization
        bytes memory clearInitializedData = abi.encodeCall(IProxyAdmin.upgradeAndCall, (payable(address(systemConfig)), address(storageSetterL1), abi.encodeWithSignature("clearSlotZero()")));

        (bool success,) = address(l1ProxyAdmin).call(clearInitializedData);
        require(success, "Unable to clear SystemConfig proxy initialization");

        uint256 initializedValue = StorageSetterRestricted(address(systemConfig)).getUint(0);

        console.log("Cleared systemconfig initialized flag, new value", initializedValue);

        // Revert to initial implementation and initialize
        {
            bytes memory upgradeAndInitializeData = abi.encodeCall(IProxyAdmin.upgradeAndCall, (payable(address(systemConfig)), systemConfigImplementationAddr, abi.encodeCall(SystemConfigCGT.initialize, (owner, basefeeScalar, blobbasefeeScalar, batcherHash, gasLimit, unsafeBlockSigner, resourceConfig, batchInbox, addresses))));

            (success,) = address(l1ProxyAdmin).call(upgradeAndInitializeData);
            console.log("succ", success);
            require(success, "Unable to upgrade and reinitialize SystemConfig proxy");

            console.log("System config reinitialized");

            console.log("Initialized flag", uint256(vm.load(address(systemConfig), 0)));
        }

        vm.stopPrank();
    }

    function upgradeL1_L1CrossDomainMessengerCGT() public {
        // Upgrade L1CrossDomainMessenger to L1CrossDomainMessengerCGT
        // ============================================
        console.log("\n========== L1CrossDomainMessengerCGT ==========");
        console.log("Upgrade L1CrossDomainMessenger to L1CrossDomainMessengerCGT");

        // Become the proxy admin owner
        vm.startPrank(l1ProxyAdminOwner);

        // Deploy the impl for L1CrossDomainMessengerCGT
        L1CrossDomainMessengerCGT l1MessengerCGTImpl = new L1CrossDomainMessengerCGT();

        // ProxyAdmin upgradeToAndCall route
        {
            // Upgrade and clear initialization
            l1ProxyAdmin.upgradeAndCall(l1CrossDomainMessengerAddress, address(storageSetterL1), abi.encodeWithSignature("clearSlotZero()"));

            uint256 initializedValue = StorageSetterRestricted(address(l1CrossDomainMessengerAddress)).getUint(0);
            console.log("Cleared L1CrossDomainMessenger initialized flag, new value", initializedValue);

            // Prepare initialization call
            bytes memory data = abi.encodeCall(l1MessengerCGTImpl.initialize, (ISuperchainConfig(superchainConfig), IOptimismPortal(optimismPortalPxyAddress), ISystemConfig(address(systemConfig))));

            // Upgrade the L1CrossDomainMessenger Proxy to use the L1CrossDomainMessengerCGT implementation
            l1ProxyAdmin.upgradeAndCall(l1CrossDomainMessengerAddress, address(l1MessengerCGTImpl), data);
        }

        vm.stopPrank();
    }

    function upgradeL1_L1StandardBridgeCGT() public {
        // Upgrade L1StandardBridge to L1StandardBridgeCGT
        // ============================================
        console.log("\n========== L1StandardBridgeCGT ==========");
        console.log("Upgrade L1StandardBridgeCGT");

        // Become the proxy admin owner
        vm.startPrank(l1ProxyAdminOwner);

        // Deploy the impl for L1StandardBridgeCGT
        L1StandardBridgeCGT bridgeCGTImpl = new L1StandardBridgeCGT();

        // ProxyAdmin upgradeToAndCall route
        {
            // Upgrade and clear initialization
            l1ProxyAdmin.upgradeAndCall(l1StdBridgePxyAddress, address(storageSetterL1), abi.encodeWithSignature("clearSlotZero()"));

            uint256 initializedValue = StorageSetterRestricted(address(l1StdBridgePxyAddress)).getUint(0);
            console.log("Cleared L1StandardBridgeCGT initialized flag, new value", initializedValue);

            // Prepare initialization call
            bytes memory data = abi.encodeCall(bridgeCGTImpl.initialize, (ICrossDomainMessenger(l1CrossDomainMessengerAddress), ISuperchainConfig(superchainConfig), ISystemConfig(address(systemConfig)), address(frxETH), address(Constants.FraxtalMainnet.WFRXETH_ERC20), address(l1SafeAddress)));

            // Upgrade the L1StandardBridgeCGT Proxy to use the L1StandardBridgeCGT implementation
            l1ProxyAdmin.upgradeAndCall(l1StdBridgePxyAddress, address(bridgeCGTImpl), data);
        }

        vm.stopPrank();
    }

    function upgradeL1_L1ERC721Bridge() public {
        // Upgrade L1ERC721Bridge
        // ============================================
        console.log("\n========== L1ERC721Bridge ==========");
        console.log("Upgrade L1ERC721Bridge");

        // Become the proxy admin owner
        vm.startPrank(l1ProxyAdminOwner);

        // Deploy the impl for L1ERC721Bridge
        L1ERC721Bridge theImpl = new L1ERC721Bridge();

        // ProxyAdmin upgradeToAndCall route
        {
            // Upgrade and clear initialization
            l1ProxyAdmin.upgradeAndCall(payable(address(l1Erc721Bridge)), address(storageSetterL1), abi.encodeWithSignature("clearSlotZero()"));

            uint256 initializedValue = StorageSetterRestricted(address(l1Erc721Bridge)).getUint(0);
            console.log("Cleared L1ERC721Bridge initialized flag, new value", initializedValue);

            // Prepare initialization call
            bytes memory data = abi.encodeCall(theImpl.initialize, (ICrossDomainMessenger(l1CrossDomainMessengerAddress), ISuperchainConfig(superchainConfig)));

            // Upgrade the L1ERC721Bridge Proxy to use the L1ERC721Bridge implementation
            l1ProxyAdmin.upgradeAndCall(payable(address(l1Erc721Bridge)), address(theImpl), data);
        }

        vm.stopPrank();
    }

    function upgradeL1_OptimismMintableERC20Factory() public {
        // Upgrade OptimismMintableERC20Factory
        // ============================================
        console.log("\n========== OptimismMintableERC20Factory ==========");
        console.log("Upgrade OptimismMintableERC20Factory");

        // Become the proxy admin owner
        vm.startPrank(l1ProxyAdminOwner);

        // Deploy the impl for OptimismMintableERC20Factory
        OptimismMintableERC20Factory theImpl = new OptimismMintableERC20Factory();

        // ProxyAdmin upgradeToAndCall route
        {
            // Upgrade and clear initialization
            l1ProxyAdmin.upgradeAndCall(payable(address(l1OptimismMintableERC20Factory)), address(storageSetterL1), abi.encodeWithSignature("clearSlotZero()"));

            uint256 initializedValue = StorageSetterRestricted(address(l1OptimismMintableERC20Factory)).getUint(0);
            console.log("Cleared OptimismMintableERC20Factory initialized flag, new value", initializedValue);

            // Prepare initialization call
            bytes memory data = abi.encodeCall(theImpl.initialize, (address(l1StdBridgePxyAddress)));

            // Upgrade the OptimismMintableERC20Factory Proxy to use the OptimismMintableERC20Factory implementation
            l1ProxyAdmin.upgradeAndCall(payable(address(l1OptimismMintableERC20Factory)), address(theImpl), data);
        }

        vm.stopPrank();
    }

    function approveAndExecSafeTx(address _to, bytes memory _calldata) public {
        // See
        // https://user-images.githubusercontent.com/33375223/211921017-b57ae2f3-0d33-4265-a87d-945a69a77ba6.png

        // Get the nonce
        uint256 _nonce = l1Safe.nonce();

        // Encode the tx
        bytes memory _encodedTxData = l1Safe.encodeTransactionData(_to, 0, _calldata, SafeOps.Operation.Call, 0, 0, 0, address(0), payable(address(0)), _nonce);

        // Sign the encoded tx
        bytes memory signature;
        if (msg.sender == vm.addr(junkDeployerPk) && tx.origin == vm.addr(junkDeployerPk)) {
            // If the caller is not a signer
            console.log("   -- Caller is not a signer");
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(junkDeployerPk, keccak256(_encodedTxData));
            signature = abi.encodePacked(r, s, v); // Note order is reversed here
            console.log("-------- Signature --------");
            console.logBytes(signature);
        } else {
            // This is the signature format used the caller is also the signer.
            console.log("   -- Caller is a signer");
            signature = abi.encodePacked(uint256(uint160(vm.addr(junkDeployerPk))), bytes32(0), uint8(1));
        }

        // // Approve the tx hash
        // // Have to static call here due to compiler issues
        // (bool _success, bytes memory _returnData) = address(l1Safe).staticcall(
        //     abi.encodeWithSelector(l1Safe.getTransactionHash.selector,
        //     _to, 0, _calldata, SafeOps.Operation.Call, 0, 0, 0, address(0), payable(address(0)), _nonce)
        // );
        // require(_success, "approveAndExecSafeTx failed");
        // _safeTxHash = abi.decode(_returnData, (bytes32));
        // console.logBytes(_returnData);

        // // Approve the hash
        // l1Safe.approveHash(_safeTxHash);

        // Execute the transaction
        l1Safe.execTransaction({ to: _to, value: 0, data: _calldata, operation: SafeOps.Operation.Call, safeTxGas: 0, baseGas: 0, gasPrice: 0, gasToken: address(0), refundReceiver: payable(address(0)), signatures: signature });
    }
}
