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

function deployNewFPISLockerImpl() returns (FPISLocker _FPISLockerImpl) {
    _FPISLockerImpl = new FPISLocker();
}

contract UpgradeFPISLocker is BaseScript {
    // Addresses
    address token = Constants.FraxtalStandardProxies.FPIS_PROXY;
    address fxs = Constants.FraxtalStandardProxies.FXS_PROXY;
    address veFxs = Constants.FraxtalStandardProxies.VEFXS_PROXY;
    address fpisLockerProxy = Constants.FraxtalStandardProxies.FPIS_LOCKER_PROXY;
    address eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
    address fpisAggregator = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;

    function run() public broadcaster {
        // Initialize the network
        string memory network = vm.envString("NETWORK");

        // Deploy the new FPISLocker implementation
        FPISLocker implementation = deployNewFPISLockerImpl();

        // // Upgrade proxy to implementation and call initialize
        // bytes memory data = abi.encodeCall(
        //     implementation.initialize,
        //     (eventualAdmin, fpisAggregator, token, fxs, veFxs, "Locked FPIS", "lFPIS", "lFPIS_1.0.0")
        // );

        // Initialize the implementation
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

        console.log("Current FPISLocker proxy: ", address(fpisLockerProxy));
        console.log("New FPISLocker implementation: ", address(implementation));
        // console.log("============== DATA ==============");
        // console.logBytes(data);
        // console.log("==================================");

        // DO THIS MANUALLY WITH THE COMPTROLLER
        console.log("NEED TO DO fpisLockerProxy.upgradeTo WITH COMPTROLLER!!!");
        console.log("NEED TO DO fpisLockerProxy.upgradeTo WITH COMPTROLLER!!!");
        console.log("NEED TO DO fpisLockerProxy.upgradeTo WITH COMPTROLLER!!!");
        // fpisLockerProxy.upgradeTo({ _implementation: address(implementation)});
    }
}
