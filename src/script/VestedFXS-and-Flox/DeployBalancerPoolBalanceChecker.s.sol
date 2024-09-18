// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { BalancerPoolBalanceChecker } from "src/contracts/VestedFXS-and-Flox/Flox/BalancerPoolBalanceChecker.sol";

function deployBalancerPoolBalanceChecker() returns (address) {
    BalancerPoolBalanceChecker balancerPoolBalanceChecker = new BalancerPoolBalanceChecker();

    return address(balancerPoolBalanceChecker);
}

contract DeployBalancerPollBalanceChecker is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address balancerPoolBalanceChecker = deployBalancerPoolBalanceChecker();
        console.log("BalancerPoolBalanceChecker deployed at: ", balancerPoolBalanceChecker);

        vm.stopBroadcast();
    }
}
