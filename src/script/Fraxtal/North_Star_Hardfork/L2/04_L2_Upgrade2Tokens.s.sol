// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L2_Upgrade2Tokens is NorthStarSharedStateScript {
    string txBatchJson =
        '{"version":"1.0","chainId":"<CHAIN_ID>","createdAt":66666666666666,"meta":{"name":"04_L2_Upgrade2Tokens","description":"","txBuilderVersion":"1.18.0","createdFromSafeAddress":"<SIGNING_SAFE_ADDRESS>","createdFromOwnerAddress":"","checksum":"<CHECKSUM>"},"transactions":[{},{},{},{}]}';
    string JSON_PATH = "src/script/Fraxtal/North_Star_Hardfork/L2/batches/04_L2_Upgrade2Tokens.json";

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
        vm.writeJson(Strings.toHexString(l2ProxyAdminCore8Owner), JSON_PATH, ".meta.createdFromSafeAddress");
    }

    function run() public virtual {
        // Set up the state
        setupState();

        // Make sure you are on L2
        vm.selectFork(l2ForkID);

        // Start broadcasting
        vm.startBroadcast(junkDeployerPk);
        console.log("Executing as", junkDeployerAddress);

        console.log("Upgrade FXS to wFRAX");
        // =======================================================

        // Note the total supply beforehand
        uint256 _tSupply = wFRAX.totalSupply();
        console.log("wFRAX.totalSupply() (before): ", _tSupply);

        // TODO: IRL Dump _tSupply gas tokens (ETH here, for now) into wFRAX
        // TODO: IRL Dump _tSupply gas tokens (ETH here, for now) into wFRAX
        // TODO: IRL Dump _tSupply gas tokens (ETH here, for now) into wFRAX
        // TODO: IRL Dump _tSupply gas tokens (ETH here, for now) into wFRAX
        // TODO: IRL Dump _tSupply gas tokens (ETH here, for now) into wFRAX
        // vm.deal(address(wFRAX), _tSupply);

        console.log("   -- Doing StorageSetterRestricted first to clear initialization slot");
        // ----------------------
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(wFRAX)),
            address(storageSetterL2),
            abi.encodeWithSignature("clearSlotOZ5Zero()")
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminCore8), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[0]");

        // (Optional) Execute the initialization clearing
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_SSCheck(address(l2ProxyAdminCore8), _theCalldata, false, payable(address(wFRAX)));
        }

        console.log("   -- Doing the actual upgrade");
        // ----------------------
        // Get the encoded initialization call
        _theEncodedCall = abi.encodeCall(wFRAX_Impl.initialize, ("Wrapped Frax", "WFRAX", "1.0.1"));

        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(wFRAX)),
            address(wFRAX_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminCore8), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[1]");

        // (Optional) Execute the upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_03_VCheck(address(l2ProxyAdminCore8), _theCalldata, false, payable(address(wFRAX)), "1.0.1");

            // Make sure the storage got updated properly
            assertEq(wFRAX.name(), "Wrapped Frax", "name not stored properly");
            assertEq(wFRAX.symbol(), "WFRAX", "symbol not stored properly");
        }

        // Reset wFRAX SigUtils
        if (SHOULD_EXECUTE) {
            sigUtils_wFRAX = new SigUtils(wFRAX.DOMAIN_SEPARATOR());
            vm.makePersistent(address(sigUtils_wFRAX));
            vm.label(address(sigUtils_wFRAX), "sigUtils_wFRAX");
            console.log("sigUtils_wFRAX deployed to: ", address(sigUtils_wFRAX));
        }

        // console.log("Upgrade wfrxETH to frxETH");
        // // =======================================================

        // // Note the total supply beforehand
        // _tSupply = address(frxETHL2).balance;
        // console.log("address(frxETHL2).balance (before): ", _tSupply);

        // console.log("   -- Doing StorageSetterRestricted first to clear initialization slot");
        // // ----------------------
        // _theCalldata = abi.encodeWithSelector(
        //     ProxyAdmin.upgradeAndCall.selector,
        //     payable(address(frxETHL2)),
        //     address(storageSetterL2),
        //     abi.encodeWithSignature("clearSlotZero()")
        // );

        // // Fill the tx json and write
        // _txJson = generateTxJson(address(l2ProxyAdminCore8), _theCalldata);
        // vm.writeJson(_txJson, JSON_PATH, ".transactions[2]");

        // // (Optional) Execute the initialization clearing
        // if (SHOULD_EXECUTE) {
        //     execSafeTx_L2_03_SSCheck(address(l2ProxyAdminCore8), _theCalldata, false, payable(address(frxETHL2)));
        // }

        // console.log("   -- Doing the actual upgrade");
        // // ----------------------
        // // Get the encoded initialization call
        // _theEncodedCall = abi.encodeCall(
        //     frxETHL2_Impl.initialize,
        //     (
        //         address(l2Safe),
        //         address(l2Safe),
        //         address(l2StandardBridge),
        //         frxETHL1Address,
        //         _tSupply,
        //         "Frax Ether",
        //         "frxETH",
        //         "1.0.0"
        //     )
        // );

        // // Get the calldata
        // _theCalldata = abi.encodeWithSelector(
        //     ProxyAdmin.upgradeAndCall.selector,
        //     payable(address(frxETHL2)),
        //     address(frxETHL2_Impl),
        //     _theEncodedCall
        // );

        // // Fill the tx json and write
        // _txJson = generateTxJson(address(l2ProxyAdminCore8), _theCalldata);
        // vm.writeJson(_txJson, JSON_PATH, ".transactions[3]");

        // // (Optional) Execute the upgrade
        // if (SHOULD_EXECUTE) {
        //     execSafeTx_L2_03_VCheck(
        //         address(l2ProxyAdminCore8),
        //         _theCalldata,
        //         false,
        //         payable(address(frxETHL2)),
        //         "1.0.1"
        //     );
        // }

        // if (SHOULD_EXECUTE) {
        //     // Make sure the storage got updated properly
        //     assertEq(frxETHL2.name(), "Frax Ether", "name not stored properly");
        //     assertEq(frxETHL2.symbol(), "frxETH", "symbol not stored properly");
        //     assertEq(frxETHL2.totalSupply(), _tSupply, "totalSupply not stored properly");
        //     assertEq(frxETHL2.BRIDGE(), address(l2StandardBridge), "BRIDGE not stored properly");
        //     assertEq(frxETHL2.REMOTE_TOKEN(), frxETHL1Address, "REMOTE_TOKEN not stored properly");
        // }

        // // Reset frxETH SigUtils
        // if (SHOULD_EXECUTE) {
        //     sigUtils_frxETH = new SigUtils(frxETHL2.DOMAIN_SEPARATOR());
        //     vm.makePersistent(address(sigUtils_frxETH));
        //     vm.label(address(sigUtils_frxETH), "sigUtils_frxETH");
        //     console.log("sigUtils_frxETH deployed to: ", address(sigUtils_frxETH));
        //     // Fraxtal Testnet 4/3/25 @ 11:13AM PST sigUtils_frxETH deployed to:  0x91A019d5fcE477eB040EF66D69EaB24c5f23020D
        // }

        vm.stopBroadcast();
    }
}
