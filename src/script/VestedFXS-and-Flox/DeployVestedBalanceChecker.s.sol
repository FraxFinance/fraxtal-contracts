// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { VestedBalanceChecker } from "src/contracts/VestedFXS-and-Flox/Flox/VestedBalanceChecker.sol";

function deployVestedBalanceChecker() returns (address) {
    VestedBalanceChecker vestedBalanceChecker = new VestedBalanceChecker();

    return address(vestedBalanceChecker);
}

contract DeployVestedBalanceCheckerAndDelegationRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address vestedBalanceChecker = deployVestedBalanceChecker();
        console.log("VestedBalanceChecker deployed at: ", vestedBalanceChecker);

        vm.stopBroadcast();
    }
}
