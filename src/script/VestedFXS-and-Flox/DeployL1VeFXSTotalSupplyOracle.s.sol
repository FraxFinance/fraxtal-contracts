// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { L1VeFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXS.sol";
import { L1VeFXSTotalSupplyOracle } from "src/contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXSTotalSupplyOracle.sol";
import "src/Constants.sol" as Constants;
import { FraxtalProxy } from "./FraxtalProxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployL1VeFXSTotalSupplyOracle(
    address _owner,
    address _bot,
    uint256 _initTtlSupplyStored,
    uint128 _initBlkWhenTtlSupplyRead,
    uint128 _initTsWhenTtlSupplyRead
) returns (L1VeFXSTotalSupplyOracle _l1VeFXSTotalSupplyOracle) {
    _l1VeFXSTotalSupplyOracle = new L1VeFXSTotalSupplyOracle(
        _owner,
        _bot,
        _initTtlSupplyStored,
        _initBlkWhenTtlSupplyRead,
        _initTsWhenTtlSupplyRead
    );
}

contract DeployL1VeFXSTotalSupplyOracle is BaseScript {
    // address
    address tempAdmin;
    address eventualAdmin;
    address botAddress;

    function run() public broadcaster returns (L1VeFXSTotalSupplyOracle _l1VeFXSTotalSupplyOracle) {
        // Initialize tempAdmin and eventualAdmin
        tempAdmin = msg.sender;
        uint256 _initTtlSupplyStored;
        uint128 _initBlkWhenTtlSupplyRead;
        uint128 _initTsWhenTtlSupplyRead;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            botAddress = 0xBB437059584e30598b3AF0154472E47E6e2a45B9;
            _initTtlSupplyStored = 93_363_562_292_164_148_659_215_055; // 06/07/2024 @ 1:51pm UTC
            _initBlkWhenTtlSupplyRead = 20_040_368; // 06/07/2024 @ 1:51pm UTC
            _initTsWhenTtlSupplyRead = 1_717_768_343; // 06/07/2024 @ 1:52pm UTC
        } else {
            // Test deploy
            botAddress = tempAdmin;
            eventualAdmin = tempAdmin;
        }

        // Deploy the L1VeFXSTotalSupplyOracle
        _l1VeFXSTotalSupplyOracle = deployL1VeFXSTotalSupplyOracle(
            eventualAdmin,
            botAddress,
            _initTtlSupplyStored,
            _initBlkWhenTtlSupplyRead,
            _initTsWhenTtlSupplyRead
        );
    }

    function runTest() external returns (L1VeFXSTotalSupplyOracle) {
        return run();
    }
}
