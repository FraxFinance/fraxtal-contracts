// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { FxtlPoints } from "src/contracts/VestedFXS-and-Flox/Flox/FxtlPoints.sol";
import { DelegationRegistry } from "src/contracts/VestedFXS-and-Flox/Flox/DelegationRegistry.sol";

function deployFxtlPoints() returns (address) {
    FxtlPoints fxtlPoints = new FxtlPoints();
    fxtlPoints.addFxtlContributor(msg.sender);

    return address(fxtlPoints);
}

function deployDelegationRegistry() returns (address) {
    DelegationRegistry delegationRegistry = new DelegationRegistry();

    return address(delegationRegistry);
}

contract DeployFxtlPointsAndDelegationRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address fxtlPoints = deployFxtlPoints();
        console.log("FxtlPoints deployed at: ", fxtlPoints);

        address delegationRegistry = deployDelegationRegistry();
        console.log("DelegationRegistry deployed at: ", delegationRegistry);

        vm.stopBroadcast();
    }
}
