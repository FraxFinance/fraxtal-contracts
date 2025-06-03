// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L2_DeployImplsAndSSs is NorthStarSharedStateScript {
    // Used for verification
    bool DEPLOY_MISC_JUNK = false;

    function setupState() internal virtual {
        super.defaultSetup();
    }

    function run() public virtual {
        // Set up the state
        setupState();

        // Make sure you are on L2
        vm.selectFork(l2ForkID);

        // Start broadcasting
        vm.startBroadcast(junkDeployerPk);
        console.log("Executing as", junkDeployerAddress);

        // Optional
        if (DEPLOY_MISC_JUNK) {
            console.log("Deploying junk contracts for verification purposes");
            // =======================================================
            address _junkOPProxyAdmin = address(new ProxyAdmin(junkDeployerAddress));
            address _junkOPProxy = address(new Proxy(address(_junkOPProxyAdmin)));

            console.log("_junkOPProxyAdmin: ", _junkOPProxyAdmin);
            console.log("_junkOPProxy: ", _junkOPProxy);
        }

        // If you reset the chain, the Gnosis safe changes so you have to find it
        console.log("True l2Safe address: ", l2ProxyAdminOpSys.owner());

        console.log("Deploy the storage setter");
        // =======================================================
        storageSetterL2 = new StorageSetterRestricted();

        console.log("Deploy the implementation for L1BlockCGT");
        // =======================================================
        l1BlockCGT_Impl = new L1BlockCGT();

        console.log("Deploy the implementation for L2ToL1MessagePasserCGT");
        // =======================================================
        l2ToL1MessagePasserCGT_Impl = new L2ToL1MessagePasserCGT();

        console.log("Deploy the implementation for L2StandardBridgeCGT");
        // =======================================================
        l2StandardBridgeCGT_Impl = new L2StandardBridgeCGT();

        console.log("Deploy the implementation for L2CrossDomainMessengerCGT");
        // =======================================================
        l2CrossDomainMessengerCGT_Impl = new L2CrossDomainMessengerCGT();

        console.log("Deploy the implementation for BaseFeeVaultCGT");
        // =======================================================
        baseFeeVaultCGT_Impl = new BaseFeeVaultCGT();

        console.log("Deploy the implementation for L1FeeVaultCGT");
        // =======================================================
        l1FeeVaultCGT_Impl = new L1FeeVaultCGT();

        console.log("Deploy the implementation for SequencerFeeVaultCGT");
        // =======================================================
        sequencerFeeVaultCGT_Impl = new SequencerFeeVaultCGT();

        // Print new storage setter and implementation addresses
        console.log("===================== L2 IMPL ADDRESSES =====================");
        console.log("address internal constant L2_STORAGE_SETTER = %s;", address(storageSetterL2));
        console.log("address internal constant L1_BLOCK_CGT_IMPL = %s;", address(l1BlockCGT_Impl));
        console.log(
            "address internal constant L2_TO_L1_MESSAGE_PASSER_CGT_IMPL = %s;",
            address(l2ToL1MessagePasserCGT_Impl)
        );
        console.log("address internal constant L2_STANDARD_BRIDGE_CGT_IMPL = %s;", address(l2StandardBridgeCGT_Impl));
        console.log(
            "address internal constant L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL = %s;",
            address(l2CrossDomainMessengerCGT_Impl)
        );
        console.log("address internal constant BASE_FEE_VAULT_CGT_IMPL = %s;", address(baseFeeVaultCGT_Impl));
        console.log("address internal constant L1_FEE_VAULT_CGT_IMPL = %s;", address(l1FeeVaultCGT_Impl));
        console.log("address internal constant SEQUENCER_FEE_VAULT_CGT_IMPL = %s;", address(sequencerFeeVaultCGT_Impl));

        vm.stopBroadcast();
    }
}
