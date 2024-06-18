// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployVeFXSAggregator() returns (VeFXSAggregator _veFXSAggregator) {
    _veFXSAggregator = new VeFXSAggregator();
}

contract DeployVeFXSAggregator is BaseScript {
    // Deploy variables
    address tempProxyAdmin;
    address eventualAdmin;
    address vestedFxsAddress; // _veAddresses[0]
    address vestedFxsUtilsAddress; // _veAddresses[1]
    address fpisLocker; // _veAddresses[2]
    address fpisLockerUtils; // _veAddresses[3]
    address l1VeFXS; // _veAddresses[4]
    address l1VeFXSTotalSupplyOracle; // _veAddresses[5]

    function run() public broadcaster returns (VeFXSAggregator _veFXSAggregator) {
        // Initialize tempProxyAdmin and eventualAdmin
        tempProxyAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            vestedFxsAddress = Constants.FraxtalMainnet.VESTED_FXS_PROXY;
            vestedFxsUtilsAddress = Constants.FraxtalMainnet.VESTED_FXS_UTILS;
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            fpisLocker = Constants.FraxtalMainnet.FPIS_LOCKER_PROXY;
            fpisLockerUtils = Constants.FraxtalMainnet.FPIS_LOCKER_UTILS;
            l1VeFXS = Constants.FraxtalMainnet.L1VEFXS_PROXY;
            l1VeFXSTotalSupplyOracle = Constants.FraxtalMainnet.L1VEFXS_TOTAL_SUPPLY_ORACLE;
        } else {
            // Test deploy
            eventualAdmin = msg.sender;
        }

        // Deploy VeFXSAggregator implementation
        console.log("<<< Deploying implementation >>>");
        VeFXSAggregator implementation = deployVeFXSAggregator();

        // Deploy VeFXSAggregator proxy
        console.log("<<< Deploying proxy >>>");
        console.log("    --- If this fails, try forge clean");
        console.log("    --- ALSO: update the salt if you need to");
        Proxy proxy = new Proxy{ salt: bytes32("VeFXSAggregatorABCDEFGH") }(tempProxyAdmin);

        // Upgrade proxy to implementation and call initialize
        console.log("<<< Doing upgradeToAndCall >>>");
        address[6] memory _veAddresses = [
            vestedFxsAddress,
            vestedFxsUtilsAddress,
            fpisLocker,
            fpisLockerUtils,
            l1VeFXS,
            l1VeFXSTotalSupplyOracle
        ];
        bytes memory data = abi.encodeCall(implementation.initialize, (eventualAdmin, eventualAdmin, _veAddresses));
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });

        // // Pass same arguments to implementation
        // console.log("<<< Initializing the implementation >>>");
        // implementation.initialize({
        //     _owner: eventualAdmin,
        //     _timelockAddress: eventualAdmin,
        //     _veAddresses: _veAddresses
        // });

        // Set proxy owner to ProxyAdmin
        console.log("<<< Changing the proxy admin [YD] >>>");
        proxy.changeAdmin({ _admin: eventualAdmin });

        // Set the YieldDistributor interface to the proxy (note: not needed - for testing clarity)
        if (!vm.envBool("IS_PROD")) _veFXSAggregator = VeFXSAggregator(address(proxy));

        console.log("======== ADDRESSES ======== ");
        console.log("Proxy: ", address(proxy));
        console.log("Implementation: ", address(implementation));
    }

    function runTest(address[6] calldata _veAddresses) external returns (VeFXSAggregator) {
        vestedFxsAddress = _veAddresses[0];
        vestedFxsUtilsAddress = _veAddresses[1];
        fpisLocker = _veAddresses[2];
        fpisLockerUtils = _veAddresses[3];
        l1VeFXS = _veAddresses[4];
        l1VeFXSTotalSupplyOracle = _veAddresses[5];
        return run();
    }
}
