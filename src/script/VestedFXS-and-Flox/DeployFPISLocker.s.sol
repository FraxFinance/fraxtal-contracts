// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { FPISLocker } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLocker.sol";
import { FPISLockerUtils } from "src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLockerUtils.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployMockFpis() returns (MintableBurnableTestERC20 _token) {
    _token = new MintableBurnableTestERC20({ name_: "mockFPIS", symbol_: "mFPIS" });
}

function deployFPISLocker() returns (FPISLocker _FPISLocker) {
    _FPISLocker = new FPISLocker();
    // _FPISLocker = new FPISLocker({
    //     _tokenAddr: _tokenAddress,
    //     _name: "Locked FPIS",
    //     _symbol: "lFPIS",
    //     _version: "lFPIS_1.0.0"
    // });
}

function deployFPISLockerUtils(address _lFPISAddress) returns (FPISLockerUtils _lockedFPISUtils) {
    _lockedFPISUtils = new FPISLockerUtils({ _FPISLocker: _lFPISAddress });
}

contract DeployFPISLocker is BaseScript {
    // address
    address token;
    address fxs;
    address veFxs;
    address tempAdmin;
    address eventualAdmin;
    address fpisAggregator;

    function run() public broadcaster returns (FPISLocker lockedFPIS, FPISLockerUtils lockedFPISUtils) {
        // load chain config

        // Initialize tempAdmin and eventualAdmin
        tempAdmin = msg.sender;

        if (false) {
            // Prod deploy
            token = Constants.FraxtalStandardProxies.FPIS_PROXY;
            fxs = Constants.FraxtalStandardProxies.FXS_PROXY;
            veFxs = Constants.FraxtalStandardProxies.VEFXS_PROXY;
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            fpisAggregator = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6; // TODP: Determine the aggregator address
        } else {
            // Test deploy
            eventualAdmin = address(0);
        }

        string memory network = vm.envString("NETWORK");
        // TODO: update the env variables
        // if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        //     eventualAdmin = Constants.FraxtalMainnet.PROXY_ADMIN;
        // } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
        //     eventualAdmin = Constants.FraxtalTestnet.PROXY_ADMIN; // TODO: @alex confirm these proxy admins
        // } else if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        //     eventualAdmin = Constants.FraxtalDevnet.PROXY_ADMIN;
        // } else if (Strings.equal(network, Constants.FraxtalDeployment.LOCAL)) { // TODO:add
        //     eventualAdmin = msg.sender;
        // } else {
        //     revert("Fix `NETWORK` in .env");
        // }

        // Deploy FPISLocker implementation and its' proxy
        FPISLocker implementation = deployFPISLocker();
        Proxy proxy = new Proxy{ salt: bytes32("lFPISABCDEFGHI") }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(
            implementation.initialize,
            (eventualAdmin, fpisAggregator, token, fxs, veFxs, "Locked FPIS", "lFPIS", "lFPIS_1.0.0")
        );
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });
        // Pass same arguments to implementation
        implementation.initialize({
            _admin: eventualAdmin,
            _fpisAggregator: fpisAggregator,
            _tokenAddr: token,
            _fxs: fxs,
            _veFxs: veFxs,
            _name: "Locked FPIS",
            _symbol: "lFPIS",
            _version: "lFPIS_1.0.0"
        });

        // Set proxy owner to ProxyAdmin
        console.log("<<< Changing Proxy Admin [DeployFPISLocker] >>>");
        proxy.changeAdmin({ _admin: eventualAdmin });

        // Set the LFPIS interface to the proxy (note: not needed - for testing clarity)
        console.log("<<< Setting lockedFPIS >>>");
        lockedFPIS = FPISLocker(address(proxy));
        console.log("<<< Setting lockedFPISUtils >>>");
        lockedFPISUtils = deployFPISLockerUtils(address(proxy));

        console.log("FPISLocker (Proxy): ", address(proxy));
        console.log("FPISLocker (Implementation): ", address(implementation));
        console.log("FPISLockerUtils: ", address(lockedFPISUtils));
    }

    function runTest(address _token, address _fxs, address _vestedFxs) external returns (FPISLocker, FPISLockerUtils) {
        token = _token;
        fxs = _fxs;
        veFxs = _vestedFxs;
        fpisAggregator = 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c; // bob
        return run();
    }
}
