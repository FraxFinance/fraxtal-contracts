// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { PoolBalanceChecker } from "src/contracts/VestedFXS-and-Flox/Flox/PoolBalanceChecker.sol";

function deployPoolBalanceChecker() returns (address) {
    PoolBalanceChecker poolBalanceChecker = new PoolBalanceChecker();

    return address(poolBalanceChecker);
}

contract DeployPoolBalanceCheckerAndDelegationRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address poolBalanceChecker = deployPoolBalanceChecker();
        console.log("PoolBalanceChecker deployed at: ", poolBalanceChecker);

        vm.stopBroadcast();
    }
}
