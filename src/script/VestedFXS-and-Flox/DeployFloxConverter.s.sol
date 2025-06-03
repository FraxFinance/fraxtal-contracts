// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FloxConverter } from "src/contracts/VestedFXS-and-Flox/Flox/FloxConverter.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployFloxConverter() returns (FloxConverter _floxConverter) {
    _floxConverter = new FloxConverter();
}

contract DeployFloxConverter is BaseScript {
    // Deploy variables
    address floxCapacitor;
    address fxtlPoints;
    address tempAdmin;
    address owner;
    bytes32 salt;

    function run() public broadcaster returns (FloxConverter floxConverter) {
        // Initialize tempAdmin and owner
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            owner = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            salt = keccak256(abi.encodePacked("floxConverter", block.timestamp));
            floxCapacitor = Constants.FraxtalMainnet.FXS_ERC20; // TODO: replace this once FloxCapacitor is deployed
            fxtlPoints = Constants.FraxtalMainnet.FXTL_POINTS;
        }

        // Deploy FloxConverter implementation and its' proxy
        FloxConverter implementation = deployFloxConverter();
        Proxy proxy = new Proxy{ salt: salt }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(
            implementation.initialize,
            (owner, floxCapacitor, fxtlPoints, "FloxConverter_v1.0.0")
        );
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });
        // Pass same arguments to implementation
        implementation.initialize({
            _owner: owner,
            _floxCapacitor: floxCapacitor,
            _fxtlPoints: fxtlPoints,
            _version: "FloxConverter_v1.0.0"
        });

        // Set the VeFXS interface to the proxy (note: not needed - for testing clarity)
        floxConverter = FloxConverter(address(proxy));
    }

    function runTest(
        address _floxCapacitor,
        address _owner,
        address _fxtlPoints,
        string memory _saltString
    ) external returns (FloxConverter) {
        floxCapacitor = _floxCapacitor;
        fxtlPoints = _fxtlPoints;
        owner = _owner;
        salt = keccak256(abi.encodePacked("floxConverter", _saltString));
        return run();
    }
}
