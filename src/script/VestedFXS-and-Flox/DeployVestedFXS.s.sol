// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployMockFxs() returns (MintableBurnableTestERC20 _token) {
    _token = new MintableBurnableTestERC20({ name_: "mockFXS", symbol_: "mFXS" });
}

function deployVestedFXS() returns (VestedFXS _vestedFXS) {
    _vestedFXS = new VestedFXS();
    // _vestedFXS = new VestedFXS({
    //     _tokenAddr: _tokenAddress,
    //     _name: "Vote-Escrowed FXS",
    //     _symbol: "veFXS",
    //     _version: "veFXS_2.0.0"
    // });
}

function deployVestedFXSUtils(address _veFXSAddress) returns (VestedFXSUtils _vestedFXSUtils) {
    _vestedFXSUtils = new VestedFXSUtils({ _vestedFXS: _veFXSAddress });
}

contract DeployVestedFXS is BaseScript {
    // Deploy variables
    address token;
    address tempAdmin;
    address eventualAdmin;
    bytes32 salt;

    function run() public broadcaster returns (VestedFXS vestedFXS, VestedFXSUtils vestedFXSUtils) {
        // Initialize tempAdmin and eventualAdmin
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            token = Constants.FraxtalStandardProxies.FXS_PROXY;
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            salt = keccak256(abi.encodePacked("veFXS", block.timestamp));
        } else {
            // Test deploy
            eventualAdmin = address(0);
        }

        string memory network = vm.envString("NETWORK");
        // TODO: update the env variables
        // if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        //     eventualAdmin = Constants.FraxtalMainnet.PROXY_ADMIN;
        //     token = Constants.FraxtalMainnet.FXS_ERC20;
        // } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
        //     eventualAdmin = Constants.FraxtalTestnet.PROXY_ADMIN; // TODO: @alex confirm these proxy admins
        //     token = Constants.FraxtalTestnet.FXS_ERC20;
        // } else if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        //     eventualAdmin = Constants.FraxtalDevnet.PROXY_ADMIN;
        //     token = Constants.FraxtalDevnet.FXS_ERC20;
        // } else if (Strings.equal(network, Constants.FraxtalDeployment.LOCAL)) { // TODO:add
        //     eventualAdmin = msg.sender;
        // } else {
        //     revert("Fix `NETWORK` in .env");
        // }

        // Deploy VestedFXS implementation and its' proxy
        VestedFXS implementation = deployVestedFXS();
        Proxy proxy = new Proxy{ salt: salt }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(
            implementation.initialize,
            (eventualAdmin, token, "Vested FXS", "veFXS", "veFXS_2.0.0")
        );
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });
        // Pass same arguments to implementation
        implementation.initialize({
            _admin: eventualAdmin,
            _tokenAddr: token,
            _name: "Vested FXS",
            _symbol: "veFXS",
            _version: "veFXS_2.0.0"
        });

        // Set proxy owner to ProxyAdmin
        proxy.changeAdmin({ _admin: eventualAdmin });

        // Set the VeFXS interface to the proxy (note: not needed - for testing clarity)
        vestedFXS = VestedFXS(address(proxy));
        vestedFXSUtils = deployVestedFXSUtils(address(proxy));

        // Set the vestedFXSUtils address on vestedFXS
        vestedFXS.setVeFXSUtils(address(vestedFXSUtils));
    }

    function runTest(address _token, string memory _saltString) external returns (VestedFXS, VestedFXSUtils) {
        token = _token;
        salt = keccak256(abi.encodePacked("veFXS", _saltString));
        return run();
    }
}
