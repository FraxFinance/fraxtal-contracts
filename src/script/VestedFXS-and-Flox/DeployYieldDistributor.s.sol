// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import { YieldDistributor } from "src/contracts/VestedFXS-and-Flox/VestedFXS/YieldDistributor.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployYieldDistributor() returns (YieldDistributor _veFXSYieldDistributor) {
    _veFXSYieldDistributor = new YieldDistributor();
}

contract DeployYieldDistributor is BaseScript {
    // Deploy variables
    address token;
    address tempProxyAdmin;
    address eventualAdmin;
    address veFXSAggregatorAddress;

    bool IS_PROD = false;

    function run() public broadcaster returns (YieldDistributor _veFXSYieldDistributor) {
        // Initialize tempProxyAdmin and eventualAdmin
        tempProxyAdmin = msg.sender;

        if (IS_PROD) {
            // Prod deploy
            token = Constants.FraxtalStandardProxies.FXS_PROXY;
            veFXSAggregatorAddress = Constants.FraxtalMainnet.VEFXS_AGGREGATOR_PROXY;
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
        } else {
            // Test deploy
            eventualAdmin = msg.sender;
        }

        // Deploy YieldDistributor implementation
        console.log("<<< Deploying implementation >>>");
        YieldDistributor implementation = deployYieldDistributor();

        // Deploy YieldDistributor proxy
        console.log("<<< Deploying proxy >>>");
        console.log("    --- If this fails, try forge clean");
        console.log("    --- ALSO: update the salt if you need to");
        Proxy proxy = new Proxy{ salt: bytes32("VeFXSYieldDistributorABCDEFGH") }(tempProxyAdmin);

        // Upgrade proxy to implementation and call initialize
        console.log("<<< Doing upgradeToAndCall >>>");
        bytes memory data = abi.encodeCall(
            implementation.initialize,
            (eventualAdmin, eventualAdmin, token, veFXSAggregatorAddress)
        );
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });

        // // Pass same arguments to implementation
        // console.log("<<< Initializing the implementation >>>");
        // implementation.initialize({
        //     _owner: eventualAdmin,
        //     _timelockAddress: eventualAdmin,
        //     _emittedToken: token,
        //     _veFXSAggregator: veFXSAggregatorAddress
        // });

        // Set proxy owner to ProxyAdmin
        console.log("<<< Changing the proxy admin [YD] >>>");
        proxy.changeAdmin({ _admin: eventualAdmin });

        // Set the YieldDistributor interface to the proxy (note: not needed - for testing clarity)
        if (!IS_PROD) _veFXSYieldDistributor = YieldDistributor(address(proxy));

        console.log("======== ADDRESSES ======== ");
        console.log("Proxy: ", address(proxy));
        console.log("Implementation: ", address(implementation));
    }

    function runTest(address _token, address _veFXSAggregatorAddress) external returns (YieldDistributor) {
        token = _token;
        IS_PROD = false;
        veFXSAggregatorAddress = _veFXSAggregatorAddress;
        return run();
    }
}
