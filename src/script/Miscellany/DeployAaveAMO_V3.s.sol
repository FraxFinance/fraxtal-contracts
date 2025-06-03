// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { AaveAMO_V3 } from "src/contracts/Miscellany/AMOs/AaveAMO/AaveAMO_V3.sol";
import "src/Constants.sol" as Constants;
import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

contract DeployAaveAMO_V3 is BaseScript {
    // Addresses
    address owner;
    address custodian;
    address timelock;
    address tempAdmin;
    address eventualAdmin;

    function run() public broadcaster returns (AaveAMO_V3 _aaveAmo) {
        // Initialize tempAdmin and eventualAdmin
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            owner = Constants.Mainnet.MAIN_MAINNET_COMPTROLLER;
            custodian = Constants.Mainnet.MAIN_MAINNET_COMPTROLLER;
            timelock = Constants.Mainnet.TIMELOCK_ADDRESS;
            eventualAdmin = Constants.Mainnet.MAIN_MAINNET_COMPTROLLER;
        } else {
            // Test deploy
            eventualAdmin = msg.sender;
        }

        // Print the timestamp
        console.log("<<< Timestamp: %s >>>", block.timestamp);

        // Set network string
        string memory network = vm.envString("NETWORK");

        // Deploy AaveAMO_V3 implementation and its' proxy
        AaveAMO_V3 implementation = new AaveAMO_V3();
        // AaveAMO_V3 implementation = AaveAMO_V3(payable(0xF14CFF695Df14A7998A2aFd84bc550285Ad3ee4F)); // Reuse existing implementation
        Proxy proxy = new Proxy{ salt: bytes32("AaveAMO_V312") }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(implementation.initialize, (owner, custodian, timelock));
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });

        // Pass same arguments to implementation
        implementation.initialize({ _owner: owner, _operator: custodian, _timelock: timelock });

        // Set proxy owner to ProxyAdmin
        console.log("<<< Changing Proxy Admin [DeployAaveAMO_V3] >>>");
        proxy.changeAdmin({ _admin: eventualAdmin });

        // Set the AaveAMO_V3 interface to the proxy (note: not needed - for testing clarity)
        console.log("<<< Setting AaveAMO_V3 >>>");
        _aaveAmo = AaveAMO_V3(payable(proxy));

        console.log("AaveAMO_V3 (Proxy): ", address(proxy));
        console.log("AaveAMO_V3 (Implementation): ", address(implementation));
    }

    function runTest(address _owner, address _custodian, address _timelock) external returns (AaveAMO_V3) {
        owner = _owner;
        custodian = _custodian;
        timelock = _timelock;
        return run();
    }
}
