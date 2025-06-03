// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FloxCapacitor } from "src/contracts/VestedFXS-and-Flox/Flox/FloxCapacitor.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployMockFxs() returns (MintableBurnableTestERC20 _token) {
    _token = new MintableBurnableTestERC20({ name_: "mockFRAX", symbol_: "mFRAX" });
}

function deployFloxCAP() returns (FloxCapacitor _floxCAP) {
    _floxCAP = new FloxCapacitor();
}

contract DeployFloxCapacitor is BaseScript {
    // Deploy variables
    address fraxStaker;
    address veFRAX;
    address tempAdmin;
    address owner;
    bytes32 salt;

    function run() public broadcaster returns (FloxCapacitor floxCAP) {
        // Initialize tempAdmin and owner
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            owner = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            salt = keccak256(abi.encodePacked("floxCAP", block.timestamp));
            fraxStaker = Constants.FraxtalMainnet.FXS_ERC20; // TODO: replace this once FXS -> FRAX migration is executed
            veFRAX = Constants.FraxtalMainnet.VEFXS_AGGREGATOR_PROXY; // TODO: replace this once FXS -> FRAX migration is executed
        }

        // Deploy FloxCAP implementation and its' proxy
        FloxCapacitor implementation = deployFloxCAP();
        Proxy proxy = new Proxy{ salt: salt }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(implementation.initialize, (fraxStaker, owner, veFRAX, 4, "FloxCAP_v1.0.0"));
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });
        // Pass same arguments to implementation
        implementation.initialize({
            _fraxStaker: fraxStaker,
            _owner: owner,
            _veFraxAggregator: veFRAX,
            _veFraxDivisor: 4,
            _version: "FloxCAP_v1.0.0"
        });

        // Set the VeFXS interface to the proxy (note: not needed - for testing clarity)
        floxCAP = FloxCapacitor(address(proxy));
    }

    function runTest(
        address _token,
        address _owner,
        address _veFRAX,
        string memory _saltString
    ) external returns (FloxCapacitor) {
        fraxStaker = _token;
        veFRAX = _veFRAX;
        owner = _owner;
        salt = keccak256(abi.encodePacked("floxCap", _saltString));
        return run();
    }
}
