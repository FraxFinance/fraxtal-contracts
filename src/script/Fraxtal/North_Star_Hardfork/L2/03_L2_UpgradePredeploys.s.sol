// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L2_UpgradePredeploys is NorthStarSharedStateScript {
    string txBatchJson =
        '{"version":"1.0","chainId":"<CHAIN_ID>","createdAt":66666666666666,"meta":{"name":"03_L2_UpgradePredeploys","description":"","txBuilderVersion":"1.18.0","createdFromSafeAddress":"<SIGNING_SAFE_ADDRESS>","createdFromOwnerAddress":"","checksum":"<CHECKSUM>"},"transactions":[{},{},{},{},{},{}]}';
    string JSON_PATH = "src/script/Fraxtal/North_Star_Hardfork/L2/batches/03_L2_UpgradePredeploys.json";

    // {
    //       "to": "0x788E44b6424A0e4160Ae4766E86640EC5a6baD5b",
    //       "value": "0",
    //       "data": "0x788E44b6424A0e4160Ae4766E86640EC5a6baD5b",
    //       "contractMethod": null,
    //       "contractInputsValues": null
    //     }

    bool SHOULD_EXECUTE = false;

    function setupState() internal virtual {
        super.defaultSetup();

        // Create the json
        vm.writeJson(txBatchJson, JSON_PATH);

        // Set misc json variables
        vm.writeJson(string(abi.encodePacked('"', Strings.toString(uint256(l2ChainID)), '"')), JSON_PATH, ".chainId");
        vm.writeJson(
            string(abi.encodePacked('"', Strings.toString(uint256(block.timestamp)), '"')),
            JSON_PATH,
            ".createdAt"
        );
        vm.writeJson(Strings.toHexString(l2ProxyAdminOpSysOwner), JSON_PATH, ".meta.createdFromSafeAddress");
    }

    function run() public virtual {
        // Set up the state
        setupState();

        // Make sure you are on L2
        vm.selectFork(l2ForkID);

        // Start broadcasting
        vm.startBroadcast(junkDeployerPk);
        console.log("Executing as", junkDeployerAddress);

        console.log("Upgrade FraxchainL1Block to L1BlockCGT");
        // =======================================================

        // Get the calldata
        // L1BlockCGT is just an upgrade and is not initializeable
        _theCalldata = abi.encodeWithSelector(ProxyAdmin.upgrade.selector, address(l1Block), address(l1BlockCGT_Impl));

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[0]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_VCheck(address(l2ProxyAdminOpSys), _theCalldata, false, address(l1Block), "1.5.1-beta.3");
        }

        console.log("Upgrade L2ToL1MessagePasser to L2ToL1MessagePasserCGT");
        // =======================================================

        // Get the calldata
        // L2ToL1MessagePasserCGT is just an upgrade and is not initializeable
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgrade.selector,
            address(l2ToL1MessagePasser),
            address(l2ToL1MessagePasserCGT_Impl)
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[1]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_VCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                address(l2ToL1MessagePasser),
                "1.1.1-beta.1"
            );
        }

        console.log("Upgrade L2CrossDomainMessenger to L2CrossDomainMessengerCGT");
        // =======================================================
        console.log("   -- Doing StorageSetterRestricted first to clear initialization slot");
        // ----------------------
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l2CrossDomainMessenger)),
            address(storageSetterL2),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[2]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_SSCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                payable(address(l2CrossDomainMessenger))
            );
        }

        console.log("   -- Doing the actual upgrade");
        // ----------------------
        // Get the encoded initialization call
        _theEncodedCall = abi.encodeCall(
            l2CrossDomainMessengerCGT_Impl.initialize,
            (CrossDomainMessenger(l1CrossDomainMessengerAddress))
        );

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l2CrossDomainMessenger)),
            address(l2CrossDomainMessengerCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[3]");

        // (Optional) Execute the upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_VCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                payable(address(l2CrossDomainMessenger)),
                "2.1.1-beta.4"
            );
        }

        console.log("Upgrade L2StandardBridge to L2StandardBridgeCGT");
        // =======================================================
        console.log("   -- Doing StorageSetterRestricted first to clear initialization slot");
        // ----------------------
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l2StandardBridge)),
            address(storageSetterL2),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[4]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_SSCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                payable(address(l2StandardBridge))
            );
        }

        console.log("   -- Doing the actual upgrade");
        // ----------------------
        // Get the encoded initialization call
        _theEncodedCall = abi.encodeCall(l2StandardBridgeCGT_Impl.initialize, (StandardBridge(l1StdBridgePxyAddress)));

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l2StandardBridge)),
            address(l2StandardBridgeCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[5]");

        // (Optional) Execute the upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_VCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                payable(address(l2StandardBridge)),
                "1.11.1-beta.3"
            );
        }

        vm.stopBroadcast();
    }
}
