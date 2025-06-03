// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC20ExPPOMWrapped } from "src/contracts/Fraxtal/universal/ERC20ExPPOMWrapped.sol";
import { ERC20ExWrappedPPOM } from "src/contracts/Fraxtal/universal/ERC20ExWrappedPPOM.sol";
import { IERC20ExPPOMWrapped } from "src/contracts/Fraxtal/universal/interfaces/IERC20ExPPOMWrapped.sol";
import { IERC20ExWrappedPPOM } from "src/contracts/Fraxtal/universal/interfaces/IERC20ExWrappedPPOM.sol";
import {
    ProxyAdmin as OZProxyAdmin,
    TransparentUpgradeableProxy as OZTUProxy
} from "@openzeppelin-4/contracts/proxy/transparent/ProxyAdmin.sol";
import { NSHelper } from "src/script/Fraxtal/North_Star_Hardfork/NSHelper.sol";
import { Script } from "forge-std/Script.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;

// Need to do this deployment isolated because of solc versioning conflict hell with Optimism
contract L2_Deploy2Tokens is Script, NSHelper {
    // Fork info
    uint256 l2ForkID;

    // For tests
    string public mnemonic;
    uint256 public junkDeployerPk;
    address public junkDeployerAddress;

    // Used for verification
    bool DEPLOY_MISC_JUNK = false;

    function defaultSetup() internal virtual {
        // L2
        // =====================================
        l2ForkID = getNSForkId(vm.envString("NS_L2_CHAIN_CHOICE"));
        NSChainType _l2Chain = getNSChainType(vm.envString("NS_L2_CHAIN_CHOICE"));
        console.log("Chain: %s", vm.envString("NS_L2_CHAIN_CHOICE"));
        console.log("Fork ID: %s", l2ForkID);

        // Mnemonics / keys
        mnemonic = getDeployerMnemonic(_l2Chain);
        junkDeployerPk = vm.deriveKey(mnemonic, 0);
        junkDeployerAddress = vm.addr(vm.deriveKey(mnemonic, 0));
    }

    function run() public virtual {
        // Set up
        defaultSetup();

        // Make sure you are on L2
        vm.selectFork(l2ForkID);

        // Start broadcasting
        vm.startBroadcast(junkDeployerPk);
        console.log("Executing as", junkDeployerAddress);

        console.log("junkDeployerPk balance: ", junkDeployerAddress.balance);

        // Optional
        if (DEPLOY_MISC_JUNK) {
            console.log("Deploying junk contracts for verification purposes");
            // =======================================================
            address _junkOZProxyAdmin = address(new OZProxyAdmin());
            address _junkOZTUProxy = address(new OZTUProxy(_junkOZProxyAdmin, junkDeployerAddress, ""));

            console.log("_junkOZProxyAdmin: ", _junkOZProxyAdmin);
            console.log("_junkOZProxy: ", _junkOZTUProxy);
        }

        console.log("Deploy the implementation for ERC20ExPPOMWrapped (FXS -> wFRAX)");
        // =======================================================
        IERC20ExPPOMWrapped wFRAX_Impl = IERC20ExPPOMWrapped(payable(address(new ERC20ExPPOMWrapped())));

        console.log("Deploy the implementation for ERC20ExWrappedPPOM (wfrxETH -> frxETH)");
        // =======================================================
        IERC20ExWrappedPPOM frxETHL2_Impl = IERC20ExWrappedPPOM(address(new ERC20ExWrappedPPOM()));

        // Print new implementation addresses
        // Need to paste in the Constants.sol
        console.log("===================== wFRAX and frxETH  =====================");
        console.log("address internal constant WFRAX_IMPL = %s;", address(wFRAX_Impl));
        console.log("address internal constant FRXETHL2_IMPL = %s;", address(frxETHL2_Impl));

        vm.stopBroadcast();
    }
}
