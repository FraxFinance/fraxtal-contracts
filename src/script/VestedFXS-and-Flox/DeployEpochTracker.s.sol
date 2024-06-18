// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { EpochTracker } from "src/contracts/VestedFXS-and-Flox/Flox/EpochTracker.sol";

function deployEpochTracker() returns (address) {
    uint256 initialEpochLength = 302_400;
    uint256 firstEpochFirstBlock = 1_781_845;
    uint256 alreadyAllocatedEpochs = 12;

    EpochTracker epochTracker = new EpochTracker(initialEpochLength, firstEpochFirstBlock);

    uint256 lastAllocatedEpoch = epochTracker.numberOfCurentlyTrackedEpochs();

    while (lastAllocatedEpoch < alreadyAllocatedEpochs) {
        epochTracker.allocatedNextEpoch();
        lastAllocatedEpoch = epochTracker.numberOfCurentlyTrackedEpochs();
    }

    return address(epochTracker);
}

contract DeployEpochTracker is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address epochTracker = deployEpochTracker();
        console.log("EpochTracker deployed at: ", epochTracker);

        vm.stopBroadcast();
    }
}
