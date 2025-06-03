// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { FraxStaker } from "src/contracts/VestedFXS-and-Flox/FraxStaker/FraxStaker.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployFraxStaker() returns (FraxStaker _fraxStaker) {
    _fraxStaker = new FraxStaker();
}

contract DeployFraxStaker is BaseScript {
    // Deploy variables
    address tempAdmin;
    address owner;
    bytes32 salt;

    function run() public broadcaster returns (FraxStaker stakedFrax) {
        // Initialize tempAdmin and owner
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            owner = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            salt = keccak256(abi.encodePacked("stakedFrax", block.timestamp));
        }

        // Deploy FraxStaker implementation and its' proxy
        FraxStaker implementation = deployFraxStaker();
        Proxy proxy = new Proxy{ salt: salt }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(implementation.initialize, (owner, "FraxStaker_v1.0.0"));
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });
        // Pass same arguments to implementation
        implementation.initialize({ _owner: owner, _version: "FraxStaker_v1.0.0" });

        // Set the VeFXS interface to the proxy (note: not needed - for testing clarity)
        stakedFrax = FraxStaker(address(proxy));
    }

    function runTest(address _owner, string memory _saltString) external returns (FraxStaker) {
        owner = _owner;
        salt = keccak256(abi.encodePacked("FraxStaker", _saltString));
        return run();
    }
}
