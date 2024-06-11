// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { BalanceChecker } from "src/contracts/VestedFXS-and-Flox/Flox/BalanceChecker.sol";

function deployBalanceChecker() returns (address) {
    BalanceChecker balanceChecker = new BalanceChecker();

    return address(balanceChecker);
}

contract DeployBalanceCheckerAndDelegationRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address balanceChecker = deployBalanceChecker();
        console.log("BalanceChecker deployed at: ", balanceChecker);

        vm.stopBroadcast();
    }
}
