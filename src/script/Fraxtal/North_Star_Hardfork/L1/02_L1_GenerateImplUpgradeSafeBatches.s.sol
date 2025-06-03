// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L1_GenerateImplUpgradeSafeBatches is NorthStarSharedStateScript {
    string txBatchJson =
        '{"version":"1.0","chainId":"<CHAIN_ID>","createdAt":66666666666666,"meta":{"name":"01_L1_GenerateSSSafeBatches","description":"","txBuilderVersion":"1.18.0","createdFromSafeAddress":"<SIGNING_SAFE_ADDRESS>","createdFromOwnerAddress":"","checksum":"<CHECKSUM>"},"transactions":[{},{},{},{},{},{}]}';
    string JSON_PATH = "src/script/Fraxtal/North_Star_Hardfork/L1/batches/02_L1_GenerateImplUpgradeSafeBatches.json";

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
        vm.writeJson(Strings.toHexString(l1ProxyAdminOwner), JSON_PATH, ".meta.createdFromSafeAddress");
    }

    function run() public virtual {
        // Set up the state
        setupState();

        // Make sure you are on L1
        vm.selectFork(l1ForkID);

        // Start broadcasting
        vm.startBroadcast(junkDeployerPk);
        console.log("Executing as", junkDeployerAddress);

        console.log("Generate the OptimismPortalCGT StgStr initialize calldata");
        // =======================================================
        // Encode the initialization call
        _theEncodedCall = abi.encodeCall(
            opPortalCGT_Impl.initialize,
            (
                IL2OutputOracle(address(l2OutputOracle)),
                ISystemConfig(address(systemConfig)),
                ISuperchainConfig(address(superchainConfig)),
                address(frxETH),
                payable(l1SafeAddress)
            )
        );

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            optimismPortalPxyAddress,
            address(opPortalCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        string memory _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[0]");

        // (Optional) Execute the implementation upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L1_02(address(l1ProxyAdmin), _theCalldata, false, optimismPortalPxyAddress, "2.8.1-beta.4");
        }

        console.log("Generate the SystemConfigCGT StgStr initialize calldata");
        // =======================================================
        console.log("   -- Fetch pre-info");

        _theEncodedCall = abi.encodeCall(
            SystemConfigCGT.initialize,
            (
                l1SafeAddress,
                basefeeScalar,
                blobbasefeeScalar,
                batcherHash,
                gasLimit,
                unsafeBlockSigner,
                sysCfgResourceConfig,
                batchInbox,
                sysCfgAddresses
            )
        );

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(systemConfig)),
            address(systemConfig_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[1]");

        // (Optional) Execute the implementation upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L1_02(address(l1ProxyAdmin), _theCalldata, false, address(systemConfig), "2.3.0");

            // Check that the gas token was set
            {
                (address _gasAddr, ) = systemConfig.gasPayingToken();
                require(_gasAddr == address(FXS), "GasPayingToken was not set on SystemConfigCGT");
            }
        }

        console.log("Generate the L1CrossDomainMessengerCGT StgStr initialize calldata");
        // =======================================================
        _theEncodedCall = abi.encodeCall(
            l1CrossDomainMessengerCGT_Impl.initialize,
            (
                ISuperchainConfig(superchainConfig),
                IOptimismPortal(optimismPortalPxyAddress),
                ISystemConfig(address(systemConfig))
            )
        );

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            l1CrossDomainMessengerAddress,
            address(l1CrossDomainMessengerCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[2]");

        // (Optional) Execute the implementation upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L1_02(address(l1ProxyAdmin), _theCalldata, false, l1CrossDomainMessengerAddress, "2.4.1-beta.2");
        }

        console.log("Generate the L1StandardBridgeCGT StgStr initialize calldata");
        // =======================================================
        _theEncodedCall = abi.encodeCall(
            l1StandardBridgeCGT_Impl.initialize,
            (
                ICrossDomainMessenger(l1CrossDomainMessengerAddress),
                ISuperchainConfig(superchainConfig),
                ISystemConfig(address(systemConfig)),
                address(FXS),
                wFRAXAddress,
                address(l1SafeAddress)
            )
        );

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            l1StdBridgePxyAddress,
            address(l1StandardBridgeCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[3]");

        // (Optional) Execute the implementation upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L1_02(address(l1ProxyAdmin), _theCalldata, false, l1StdBridgePxyAddress, "2.2.1-beta.2");
        }

        console.log("Generate the L1ERC721Bridge StgStr initialize calldata");
        // =======================================================
        _theEncodedCall = abi.encodeCall(
            l1ERC721Bridge_Impl.initialize,
            (ICrossDomainMessenger(l1CrossDomainMessengerAddress), ISuperchainConfig(superchainConfig))
        );

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l1Erc721Bridge)),
            address(l1ERC721Bridge_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[4]");

        // (Optional) Execute the implementation upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L1_02(address(l1ProxyAdmin), _theCalldata, false, address(l1Erc721Bridge), "2.2.0-beta.1");
        }

        console.log("Generate the OptimismMintableERC20Factory StgStr initialize calldata");
        // =======================================================
        _theEncodedCall = abi.encodeCall(
            optimismMintableERC20Factory_Impl_L1.initialize,
            (address(l1StdBridgePxyAddress))
        );

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l1OptimismMintableERC20Factory)),
            address(optimismMintableERC20Factory_Impl_L1),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l1ProxyAdmin), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[5]");

        // (Optional) Execute the implementation upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L1_02(
                address(l1ProxyAdmin),
                _theCalldata,
                false,
                address(l1OptimismMintableERC20Factory),
                "1.10.1-beta.4"
            );
        }

        vm.stopBroadcast();
    }
}
