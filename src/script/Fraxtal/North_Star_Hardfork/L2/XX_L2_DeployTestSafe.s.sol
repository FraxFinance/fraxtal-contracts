// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IGnosisSafe, Enum as SafeOps } from "src/contracts/Fraxtal/interfaces/IGnosisSafe.sol";
import { GnosisSafe } from "lib/optimism/packages/contracts-bedrock/lib/safe-contracts/contracts/GnosisSafe.sol";
import { GnosisSafeL2 } from "lib/optimism/packages/contracts-bedrock/lib/safe-contracts/contracts/GnosisSafeL2.sol";
import {
    GnosisSafeProxy
} from "lib/optimism/packages/contracts-bedrock/lib/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import {
    GnosisSafeProxyFactory
} from "lib/optimism/packages/contracts-bedrock/lib/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import { IProxyAdmin } from "@eth-optimism/contracts-bedrock/src/universal/interfaces/IProxyAdmin.sol";
// import { CompatibilityFallbackHandler } from 'lib/optimism/packages/contracts-bedrock/lib/safe-contracts/contracts/handler/CompatibilityFallbackHandler.sol';
import { Script } from "forge-std/Script.sol";
import { NSHelper } from "src/script/Fraxtal/North_Star_Hardfork/NSHelper.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;

// Need to do this deployment isolated because of solc versioning conflict hell with Optimism
contract L2_DeployTestSafe is Script, NSHelper {
    // Fork info
    uint256 l2ForkID;

    // For tests
    string public mnemonic;
    uint256 public junkDeployerPk;
    address public junkDeployerAddress;

    // Optional
    bool DEPLOY_TEST_SAFE = false;
    bool TRANSFER_OWNERSHIP_TO_TEST_SAFE = false;

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

        // May need for testing
        if (DEPLOY_TEST_SAFE) {
            address[] memory owners = new address[](1);
            owners[0] = junkDeployerAddress;
            GnosisSafeL2 singleton = new GnosisSafeL2();
            GnosisSafeProxyFactory proxyFactory = new GnosisSafeProxyFactory();
            // CompatibilityFallbackHandler handler = new CompatibilityFallbackHandler();

            bytes memory _safeInitData = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owners,
                1,
                address(0),
                "",
                address(0), // address(handler)
                address(0),
                0,
                payable(address(0))
            );

            GnosisSafeProxy deployedSafeProxy = proxyFactory.createProxy(address(singleton), _safeInitData);

            console.log("===================== Test Gnosis Safe  =====================");
            console.log("address internal constant TEST_SAFE_SINGLETON = %s;", address(singleton));
            console.log("address internal constant TEST_SAFE_PROXY_FACTORY = %s;", address(proxyFactory));
            // console.log("address internal constant TEST_SAFE_COMP_FLBCK_HNDLR = %s;", address(handler));
            console.log("address internal constant TEST_DEPLOYED_SAFE_PROXY = %s;", address(deployedSafeProxy));

            return;
        }

        // May need for testing
        if (TRANSFER_OWNERSHIP_TO_TEST_SAFE) {
            IGnosisSafe _safe = IGnosisSafe(payable(address(Constants.FraxtalL2Devnet.TEST_DEPLOYED_SAFE_PROXY)));
            bytes memory _calldata = "";
            address _to = address(0);
            uint256 _value = 1000 gwei;

            // Get the nonce
            uint256 _nonce = IGnosisSafe(payable(address(_safe))).nonce();

            // Make sure the Safe is working first
            // =====================================
            // Give the safe some funds
            payable(address(_safe)).call{ value: 1000 gwei }("");

            // Encode the tx
            bytes memory _encodedTxData = IGnosisSafe(payable(address(_safe))).encodeTransactionData(
                _to,
                _value,
                _calldata,
                SafeOps.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                _nonce
            );

            // Sign the encoded tx
            bytes memory signature;
            {
                (uint8 v, bytes32 r, bytes32 s) = vm.sign(junkDeployerPk, keccak256(_encodedTxData));
                signature = abi.encodePacked(r, s, v); // Note order is reversed here
                console.log("-------- Signature --------");
                console.logBytes(signature);
            }

            // Execute the transaction
            IGnosisSafe(payable(address(_safe))).execTransaction({
                to: _to,
                value: _value,
                data: _calldata,
                operation: SafeOps.Operation.Call,
                safeTxGas: 0,
                baseGas: 0,
                gasPrice: 0,
                gasToken: address(0),
                refundReceiver: payable(address(0)),
                signatures: signature
            });

            // Transfer Ownership
            IProxyAdmin(0xfC00000000000000000000000000000000000009).transferOwnership(
                Constants.FraxtalL2Devnet.TEST_DEPLOYED_SAFE_PROXY
            );
        }

        vm.stopBroadcast();
    }
}
