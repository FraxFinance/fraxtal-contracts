// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { TimedLocker } from "src/contracts/Miscellany/TimedLocker.sol";
import "src/Constants.sol" as Constants;
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

contract DeployTimedLocker is BaseScript {
    // Deploy variables
    address stakingToken;
    address rewardToken;
    address tempAdmin;
    address eventualAdmin;
    address extraNotifier;

    // Temporary names
    string tmpName;
    string tmpSymbol;
    uint256 tmpEndTs;
    uint256 tmpCap;

    function run() public broadcaster returns (TimedLocker _timedLocker) {
        // Initialize tempProxyAdmin and eventualAdmin
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            stakingToken = Constants.FraxtalMainnet.FXB_20261231;
            rewardToken = Constants.FraxtalStandardProxies.FXS_PROXY;
            tmpName = "Locked FXB 20261231";
            tmpSymbol = "lFXB_20261231";
            tmpEndTs = 1_798_761_600;
            tmpCap = 2_500_000e18;
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            extraNotifier = 0x5180db0237291A6449DdA9ed33aD90a38787621c;
        } else {
            // Test deploy
            tmpName = "Locked FXB 20251231";
            tmpSymbol = "lFXB_20251231";
            tmpEndTs = 1_767_254_400;
            tmpCap = 2_500_000e18;
            eventualAdmin = msg.sender;
            extraNotifier = 0x0000000000000000000000000000000000000000;
        }

        // Setup the reward token array
        address[] memory _rewTokens = new address[](1);
        _rewTokens[0] = rewardToken;

        // Deploy TimedLocker
        _timedLocker = new TimedLocker({
            _owner: eventualAdmin,
            _rewardTokens: _rewTokens,
            _stakingToken: stakingToken,
            _name: tmpName,
            _symbol: tmpSymbol,
            _endingTimestamp: tmpEndTs,
            _cap: tmpCap,
            _extraNotifier: extraNotifier
        });

        console.log("======== ADDRESSES ======== ");
        console.log("TimedLocker: ", address(_timedLocker));
    }

    function runTest(address _stakingToken, address _rewardToken) external returns (TimedLocker) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        return run();
    }
}
