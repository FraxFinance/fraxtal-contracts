// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { FraxswapDepositBalanceChecker } from "src/contracts/VestedFXS-and-Flox/Flox/FraxswapDepositBalanceChecker.sol";
import {
    FraxswapCollateralBalanceChecker
} from "src/contracts/VestedFXS-and-Flox/Flox/FraxswapCollateralBalanceChecker.sol";

function deployDepositBalanceChecker() returns (address) {
    FraxswapDepositBalanceChecker depositBalanceChecker = new FraxswapDepositBalanceChecker();

    return address(depositBalanceChecker);
}

function deployCollateralBalanceChecker() returns (address) {
    FraxswapCollateralBalanceChecker collateralBalanceChecker = new FraxswapCollateralBalanceChecker();

    return address(collateralBalanceChecker);
}

contract DeployFraxswapBalanceCheckers is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address depositBalanceChecker = deployDepositBalanceChecker();
        console.log("FraxswapDepositBalanceChecker deployed at: ", depositBalanceChecker);

        address collateralBalanceChecker = deployCollateralBalanceChecker();
        console.log("FraxswapCollateralBalanceChecker deployed at: ", collateralBalanceChecker);

        vm.stopBroadcast();
    }
}
