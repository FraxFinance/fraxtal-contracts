// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L2_FixProxyAdmins is NorthStarSharedStateScript {
    function setupState() internal virtual {
        super.defaultSetup();
    }

    function run() public virtual {
        // Set up
        defaultSetup();

        // Make sure you are on L2
        vm.selectFork(l2ForkID);

        // Start broadcasting
        vm.startBroadcast(junkDeployerPk);
        console.log("Executing as", junkDeployerAddress);

        console.log("Fix wFRAX");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.changeProxyAdmin.selector,
            payable(address(wFRAX)),
            address(l2ProxyAdminCore8)
        );

        // (Optional) Execute the upgrade
        execL2SafeSpecifiedSafeTx(address(l2ProxyAdminRsvd10K), _theCalldata, false, l2Safe);

        console.log("Fix wfrxETH");
        // =======================================================
        // Get the calldata
        _theCalldata = abi.encodeWithSelector(
            ProxyAdmin.changeProxyAdmin.selector,
            payable(address(frxETHL2)),
            address(l2ProxyAdminCore8)
        );

        // (Optional) Execute the upgrade
        execL2SafeSpecifiedSafeTx(address(l2ProxyAdminRsvd10K), _theCalldata, false, l2Safe);

        vm.stopBroadcast();
    }
}
