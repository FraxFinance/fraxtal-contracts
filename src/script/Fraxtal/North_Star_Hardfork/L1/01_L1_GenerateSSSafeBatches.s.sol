// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L1_GenerateSSSafeBatches is NorthStarSharedStateScript {
    string txBatchJson =
        '{"version":"1.0","chainId":"<CHAIN_ID>","createdAt":66666666666666,"meta":{"name":"01_L1_GenerateSSSafeBatches","description":"","txBuilderVersion":"1.18.0","createdFromSafeAddress":"<SIGNING_SAFE_ADDRESS>","createdFromOwnerAddress":"","checksum":"<CHECKSUM>"},"transactions":[{},{},{},{},{},{}]}';
    string JSON_PATH = "src/script/Fraxtal/North_Star_Hardfork/L1/batches/01_L1_GenerateSSSafeBatches.json";

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
        vm.writeJson(Strings.toString(uint256(1)), JSON_PATH, ".chainId");
        vm.writeJson(Strings.toString(uint256(block.timestamp)), JSON_PATH, ".createdAt");
        vm.writeJson(Strings.toHexString(l1ProxyAdminOwner), JSON_PATH, ".meta.createdFromSafeAddress");

        // Misc info
        // _safeThreshold = l1Safe.getThreshold();
        // console.log("_safeThreshold: ", _safeThreshold);
        // _safeOwners = l1Safe.getOwners();
        // console.log("_safeOwners[0]: ", _safeOwners[0]);
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

        // Print the l1Safe
        console.log("l1Safe: ", address(l1Safe));

        console.log("Generate the OptimismPortalCGT StgStr upgradeAndCall calldata");
        // =======================================================

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            optimismPortalPxyAddress,
            address(storageSetterL1),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // console.log("optimismPortalPxyAddress: ", optimismPortalPxyAddress);
        // console.log("address(storageSetterL1): ", address(storageSetterL1));
        // console.log("----------- abi.encodeWithSignature -----------");
        // console.logBytes(abi.encodeWithSignature("clearSlotZero()"));
        // console.log("----------- abi._theCalldata -----------");
        // console.logBytes(_theCalldata);

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[0]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) execSafeTx_L1_01(address(l1ProxyAdmin), _theCalldata, false, optimismPortalPxyAddress);

        console.log("Generate the SystemConfigCGT StgStr upgradeAndCall calldata");
        // =======================================================

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(systemConfig)),
            address(storageSetterL1),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[1]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) execSafeTx_L1_01(address(l1ProxyAdmin), _theCalldata, false, address(systemConfig));

        console.log("Generate the L1CrossDomainMessengerCGT StgStr upgradeAndCall calldata");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            l1CrossDomainMessengerAddress,
            address(storageSetterL1),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[2]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) execSafeTx_L1_01(address(l1ProxyAdmin), _theCalldata, false, l1CrossDomainMessengerAddress);

        console.log("Generate the L1StandardBridgeCGT StgStr upgradeAndCall calldata");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            l1StdBridgePxyAddress,
            address(storageSetterL1),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[3]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) execSafeTx_L1_01(address(l1ProxyAdmin), _theCalldata, false, l1StdBridgePxyAddress);

        console.log("Generate the L1ERC721Bridge StgStr upgradeAndCall calldata");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l1Erc721Bridge)),
            address(storageSetterL1),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[4]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) execSafeTx_L1_01(address(l1ProxyAdmin), _theCalldata, false, address(l1Erc721Bridge));

        console.log("Generate the OptimismMintableERC20Factory StgStr upgradeAndCall calldata");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l1OptimismMintableERC20Factory)),
            address(storageSetterL1),
            abi.encodeWithSignature("clearSlotZero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[5]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) {
            execSafeTx_L1_01(address(l1ProxyAdmin), _theCalldata, false, address(l1OptimismMintableERC20Factory));
        }

        vm.stopBroadcast();
    }
}
