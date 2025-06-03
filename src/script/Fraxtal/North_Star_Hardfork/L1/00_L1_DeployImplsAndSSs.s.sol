// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L1_DeployImplsAndSSs is NorthStarSharedStateScript {
    bool SEED_L1_BRIDGE_AND_PORTAL = false;
    bool DEPLOY_DUMMIES_FOR_VERIFICATION = false;
    bool RESET_SYSTEMCONFIG = false;
    bool RESET_OPTIMISM_PORTAL = false;
    bool BRIDGE_TEST_ETH = false;

    address oldOptimismPortalImplAddress;
    address oldSystemConfigImplAddress;

    function setupState() internal virtual {
        super.defaultSetup();

        // oldSystemConfigImplAddress = _useDN
        //     ? Constants.FraxtalL1Devnet.SYSTEM_CONFIG_IMPL_OLD
        //     : Constants.FraxtalL1Ethereum.SYSTEM_CONFIG_IMPL_V2_ADDR;

        // oldOptimismPortalImplAddress = _useDN
        //     ? Constants.FraxtalL1Devnet.OPTIMISM_PORTAL_IMPL_OLD
        //     : Constants.FraxtalL1Ethereum.OPTIMISM_PORTAL_IMPL_V2_ADDR;
    }

    function run() public virtual {
        // Set up the state
        setupState();

        // Make sure you are on L1
        vm.selectFork(l1ForkID);

        // Start broadcasting
        vm.startBroadcast(junkDeployerPk);
        console.log("Executing as", junkDeployerAddress);

        // If you reset the chain, the Gnosis safe changes so you have to find it
        console.log("True l1Safe address: ", l1ProxyAdmin.owner());

        // // Print SystemConfig Info
        // printSystemConfigInfo();

        // return;

        // Seed some L1 core tokens to the L1StandardBridgeCGT and the OptimismPortalCGT
        // NEED TO DO DEPOSITS, NOT DUMP SENDS. Because the Portal and Bridges have mapping checking values
        // if (SEED_L1_BRIDGE_AND_PORTAL) {
        //     // CANNOT SIMPLY SEND. NEED TO DEPOSIT!!!

        //     // Seed FXS to OptimismPortalCGT
        //     optimismPortalCGT.
        //     FXS.transfer(address(optimismPortalCGT), 10e18);

        //     // Seed FXS to L1CrossDomainMessengerCGT
        //     FXS.transfer(address(l1CrossDomainMessenger), 10e18);

        //     // Seed FXS to L1StandardBridgeCGT
        //     FXS.transfer(address(l1StandardBridgeCGT), 10e18);

        //     // Seed frxETH to L1StandardBridgeCGT
        //     frxETH.transfer(address(l1StandardBridgeCGT), 10e18);

        //     // Return early
        //     return;
        // }

        // Deploy and verify some dummy constracts to save time vs manual verification
        if (DEPLOY_DUMMIES_FOR_VERIFICATION) {
            address junkProxy = address(new Proxy{ salt: bytes32(block.timestamp) }(l1ProxyAdminOwner));
            return;
        }

        // May need to reset the SystemConfig so you can get the stored values again
        // So just upgrade, but not upgradeAndCall
        if (RESET_SYSTEMCONFIG) {
            // Get the calldata
            _theCalldata = abi.encodeWithSelector(
                ProxyAdmin.upgrade.selector,
                payable(address(systemConfig)),
                oldSystemConfigImplAddress
            );
            // Constants.FraxtalL1Devnet.SYSTEM_CONFIG_IMPL

            execSafeTx_L1_00(address(l1ProxyAdmin), _theCalldata, false);
        }

        // May need to reset the OptimismPortal
        // So just upgrade, but not upgradeAndCall
        if (RESET_OPTIMISM_PORTAL) {
            // Get the calldata
            _theCalldata = abi.encodeWithSelector(
                ProxyAdmin.upgrade.selector,
                payable(address(optimismPortalPxy)),
                oldOptimismPortalImplAddress
            );
            // Constants.FraxtalL1Devnet.OPTIMISM_PORTAL_IMPL

            execSafeTx_L1_00(address(l1ProxyAdmin), _theCalldata, false);
        }

        // Deposit ETH to L2
        if (BRIDGE_TEST_ETH) {
            // Deposit ETH via fallback
            (payable(address(optimismPortalPxy))).call{ value: 25 ether }("");
        }

        // Return early if doing special actions
        if (DEPLOY_DUMMIES_FOR_VERIFICATION || RESET_SYSTEMCONFIG || RESET_OPTIMISM_PORTAL || BRIDGE_TEST_ETH) return;

        console.log("Deploy the storage setter");
        // =======================================================
        storageSetterL1 = new StorageSetterRestricted();

        console.log("Deploy the implementation for OptimismPortalCGT");
        // =======================================================
        opPortalCGT_Impl = new OptimismPortalCGT();

        console.log("Deploy the implementation for SystemConfig");
        // =======================================================
        systemConfig_Impl = new SystemConfigCGT();

        console.log("Deploy the implementation for L1CrossDomainMessengerCGT");
        // =======================================================
        l1CrossDomainMessengerCGT_Impl = new L1CrossDomainMessengerCGT();

        console.log("Deploy the implementation for L1StandardBridgeCGT");
        // =======================================================
        l1StandardBridgeCGT_Impl = new L1StandardBridgeCGT();

        console.log("Deploy the implementation for L1ERC721Bridge");
        // =======================================================
        l1ERC721Bridge_Impl = new L1ERC721Bridge();

        console.log("Deploy the implementation for OptimismMintableERC20Factory");
        // =======================================================
        optimismMintableERC20Factory_Impl_L1 = new OptimismMintableERC20Factory();

        // Check ending implementation versions
        assertEq(
            l1CrossDomainMessengerCGT_Impl.version(),
            "2.4.1-beta.2",
            "Wrong End L1 L1CrossDomainMessengerCGT version"
        );
        assertEq(l1ERC721Bridge_Impl.version(), "2.2.0-beta.1", "Wrong End L1 L1ERC721Bridge version");
        assertEq(l1StandardBridgeCGT_Impl.version(), "2.2.1-beta.2", "Wrong End L1 L1StandardBridgeCGT version");
        assertEq(
            optimismMintableERC20Factory_Impl_L1.version(),
            "1.10.1-beta.4",
            "Wrong End L1 OptimismMintableERC20Factory version"
        );
        assertEq(opPortalCGT_Impl.version(), "2.8.1-beta.4", "Wrong End L1 OptimismPortalCGT version");
        assertEq(systemConfig_Impl.version(), "2.3.0", "Wrong End L1 SystemConfigCGT version");

        // Print new storage setter and implementation addresses
        // Need to paste in the Constants.sol
        console.log("===================== L1 IMPL ADDRESSES =====================");
        console.log("address internal constant L1_STORAGE_SETTER = %s;", address(storageSetterL1));
        console.log(
            "address internal constant L1_CROSS_DOMAIN_MESSENGER_IMPL = %s;",
            address(l1CrossDomainMessengerCGT_Impl)
        );
        console.log("address internal constant L1_ERC721_BRIDGE_IMPL = %s;", address(l1ERC721Bridge_Impl));
        console.log("address internal constant L1_STANDARD_BRIDGE_IMPL = %s;", address(l1StandardBridgeCGT_Impl));
        console.log(
            "address internal constant OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL = %s;",
            address(optimismMintableERC20Factory_Impl_L1)
        );
        console.log("address internal constant OPTIMISM_PORTAL_IMPL = %s;", address(opPortalCGT_Impl));
        console.log("address internal constant SYSTEM_CONFIG_IMPL = %s;", address(systemConfig_Impl));

        // Print SystemConfig Info
        printSystemConfigInfo();

        vm.stopBroadcast();
    }
}
