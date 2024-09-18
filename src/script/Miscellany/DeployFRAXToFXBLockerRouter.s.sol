// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { FRAXToFXBLockerRouter } from "src/contracts/Miscellany/FRAXToFXBLockerRouter.sol";
import "src/Constants.sol" as Constants;
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

contract DeployFRAXToFXBLockerRouter is BaseScript {
    // Deploy variables
    address eventualAdmin;

    function run() public broadcaster returns (FRAXToFXBLockerRouter _routerLocker) {
        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
        } else {
            // Test deploy
            eventualAdmin = msg.sender;
        }

        // Deploy FRAXToFXBLockerRouter
        _routerLocker = new FRAXToFXBLockerRouter({ _owner: eventualAdmin });

        console.log("======== ADDRESSES ======== ");
        console.log("FRAXToFXBLockerRouter: ", address(_routerLocker));
    }

    function runTest() external returns (FRAXToFXBLockerRouter) {
        return run();
    }
}
