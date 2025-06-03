// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L2_UpgradeFeeVaults is NorthStarSharedStateScript {
    string txBatchJson =
        '{"version":"1.0","chainId":"<CHAIN_ID>","createdAt":66666666666666,"meta":{"name":"02_L2_UpgradeFeeVaults","description":"","txBuilderVersion":"1.18.0","createdFromSafeAddress":"<SIGNING_SAFE_ADDRESS>","createdFromOwnerAddress":"","checksum":"<CHECKSUM>"},"transactions":[{},{},{}]}';
    string JSON_PATH = "src/script/Fraxtal/North_Star_Hardfork/L2/batches/02_L2_UpgradeFeeVaults.json";

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

        // If you reset the chain, the Gnosis safe changes so you have to find it
        console.log("True l2Safe address: ", l2ProxyAdminOpSys.owner());

        // Print the l2Safe
        console.log("l2Safe: ", address(l2Safe));

        console.log("Prepare the initialization call");
        // =======================================================
        // Encode the initialization call. It is the same for all 3 fee vaults
        _theEncodedCall = abi.encodeCall(
            baseFeeVaultCGT_Impl.initialize,
            (l2SafeAddress, 1 ether, Types.WithdrawalNetwork.L2)
        );

        console.log("Upgrade the implementation of BaseFeeVault to BaseFeeVaultCGT");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(baseFeeVaultCGT)),
            address(baseFeeVaultCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        string memory _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[0]");

        // (Optional) Execute the upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_02_VCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                address(baseFeeVaultCGT),
                "1.5.0-beta.3"
            );
        }

        console.log("Upgrade the implementation of L1FeeVault to L1FeeVaultCGT");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(l1FeeVaultCGT)),
            address(l1FeeVaultCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[1]");

        // (Optional) Execute the upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_02_VCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                address(l1FeeVaultCGT),
                "1.5.0-beta.3"
            );
        }

        console.log("Upgrade the implementation of SequencerFeeVault to SequencerFeeVaultCGT");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector,
            payable(address(sequencerFeeVaultCGT)),
            address(sequencerFeeVaultCGT_Impl),
            _theEncodedCall
        );

        // Fill the tx json and write
        _txJson = generateTxJson(address(l2ProxyAdminOpSys), _theCalldata);
        vm.writeJson(_txJson, JSON_PATH, ".transactions[2]");

        // (Optional) Execute the upgrade
        if (SHOULD_EXECUTE) {
            execSafeTx_L2_02_VCheck(
                address(l2ProxyAdminOpSys),
                _theCalldata,
                false,
                address(sequencerFeeVaultCGT),
                "1.5.0-beta.3"
            );
        }

        vm.stopBroadcast();
    }
}
