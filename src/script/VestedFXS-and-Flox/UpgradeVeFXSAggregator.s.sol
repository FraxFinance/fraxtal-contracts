// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { VeFXSAggregator } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployNewVeFXSAggregatorImpl() returns (VeFXSAggregator _veFXSAggregatorImpl) {
    _veFXSAggregatorImpl = new VeFXSAggregator();
}

contract UpgradeVeFXSAggregator is BaseScript {
    // Deploy variables
    address tempProxyAdmin;
    address eventualAdmin = Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG;
    address vestedFxsAddress = Constants.FraxtalMainnet.VESTED_FXS_PROXY; // _veAddresses[0]
    address vestedFxsUtilsAddress = Constants.FraxtalMainnet.VESTED_FXS_UTILS; // _veAddresses[1]
    address fpisLocker = Constants.FraxtalMainnet.FPIS_LOCKER_PROXY; // _veAddresses[2]
    address fpisLockerUtils = Constants.FraxtalMainnet.FPIS_LOCKER_UTILS; // _veAddresses[3]
    address l1VeFXS = Constants.FraxtalMainnet.L1VEFXS_PROXY; // _veAddresses[4]
    address l1VeFXSTotalSupplyOracle = Constants.FraxtalMainnet.L1VEFXS_TOTAL_SUPPLY_ORACLE; // _veAddresses[5]

    function run() public broadcaster {
        // Initialize the network
        string memory network = vm.envString("NETWORK");

        // Deploy the new VeFXSAggregator implementation
        VeFXSAggregator implementation = deployNewVeFXSAggregatorImpl();

        // Prepare addresses
        address[6] memory _veAddresses = [
            vestedFxsAddress,
            vestedFxsUtilsAddress,
            fpisLocker,
            fpisLockerUtils,
            l1VeFXS,
            l1VeFXSTotalSupplyOracle
        ];

        // Initialize the implementation
        implementation.initialize({
            _owner: eventualAdmin,
            _timelockAddress: eventualAdmin,
            _veAddresses: _veAddresses
        });

        console.log("New VeFXSAggregator implementation: ", address(implementation));
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
