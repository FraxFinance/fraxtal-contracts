// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { L1VeFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXS.sol";
import { L1VeFXSTotalSupplyOracle } from "src/contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXSTotalSupplyOracle.sol";
import "src/Constants.sol" as Constants;
import { FraxtalProxy } from "./FraxtalProxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployL1VeFXS(
    address _stateRootOracle,
    address _proxyAdminOwner,
    address _implementationOwner
) returns (address) {
    bytes32 salt = bytes32("L1VeFXS1");

    // deploy implementation
    address implementation = address(new L1VeFXS{ salt: salt }());

    // deploy proxy && Atomically initialize the implementation
    bytes memory data = abi.encodeCall(L1VeFXS.initialize, (_stateRootOracle, _implementationOwner));
    FraxtalProxy proxy = new FraxtalProxy{ salt: salt }(implementation, _proxyAdminOwner, data);

    console.log("==================== FraxtalProxy Info ====================");
    console.log("<<<<< implementation >>>>>");
    console.log(implementation);
    console.log("<<<<< _proxyAdminOwner >>>>>");
    console.log(_proxyAdminOwner);
    console.log("<<<<< data >>>>>");
    console.logBytes(data);

    return payable(address(proxy));
}

contract DeployL1VeFXS is BaseScript {
    // address
    address token;
    address tempAdmin;
    address eventualAdmin;

    function run() public broadcaster returns (L1VeFXS _l1veFXS) {
        // Initialize tempAdmin and eventualAdmin
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
        } else {
            // Test deploy
            eventualAdmin = address(0);
        }

        // Deploy l1veFXS
        _l1veFXS = L1VeFXS(
            deployL1VeFXS({
                _stateRootOracle: Constants.FraxtalMainnet.FRAXTAL_STATE_ROOT_ORACLE,
                _proxyAdminOwner: Constants.FraxtalMainnet.FRAXTAL_ADMIN_SAFE, // avoid "admin cannot fallback to proxy target" clash
                _implementationOwner: tempAdmin
            })
        );
    }

    function runTest() external returns (L1VeFXS) {
        return run();
    }
}
