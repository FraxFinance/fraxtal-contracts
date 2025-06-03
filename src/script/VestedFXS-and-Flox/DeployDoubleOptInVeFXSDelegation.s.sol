// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { DoubleOptInVeFXSDelegation } from "src/contracts/VestedFXS-and-Flox/VestedFXS/DoubleOptInVeFXSDelegation.sol";
import "src/Constants.sol" as Constants;
import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployDoubleOptInVeFXSDelegation() returns (DoubleOptInVeFXSDelegation _delegation) {
    _delegation = new DoubleOptInVeFXSDelegation();
}

contract DeployDoubleOptInVeFXSDelegation is BaseScript {
    address aggregator;

    function run() public broadcaster returns (DoubleOptInVeFXSDelegation _delegation) {
        // Deploy variables
        address tempProxyAdmin = msg.sender;
        address eventualAdmin;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            aggregator = 0x176A4e081653EbB8a2246BAfbfCf663782426531;
        } else {
            // Test deploy
            eventualAdmin = msg.sender;
        }

        // Deploy DoubleOptInVeFXSDelegation implementation
        console.log("<<< Deploying implementation >>>");
        DoubleOptInVeFXSDelegation implementation = deployDoubleOptInVeFXSDelegation();

        // Deploy DoubleOptInVeFXSDelegation proxy
        console.log("<<< Deploying proxy >>>");
        console.log("    --- If this fails, try forge clean");
        console.log("    --- ALSO: update the salt if you need to");
        Proxy proxy = new Proxy{ salt: bytes32("DoubleOptInVeFXSDelegation123") }(tempProxyAdmin);

        // Upgrade proxy to implementation and call initialize
        console.log("<<< Doing upgradeToAndCall >>>");
        bytes memory data = abi.encodeCall(implementation.initialize, (eventualAdmin, aggregator));
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
        if (!vm.envBool("IS_PROD")) _delegation = DoubleOptInVeFXSDelegation(address(proxy));

        console.log("======== ADDRESSES ======== ");
        console.log("Proxy: ", address(proxy));
        console.log("Implementation: ", address(implementation));
    }

    function runTest(address _aggregator) external returns (DoubleOptInVeFXSDelegation) {
        aggregator = _aggregator;

        return run();
    }
}
