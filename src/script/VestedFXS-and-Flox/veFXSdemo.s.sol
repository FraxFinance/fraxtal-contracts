// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "frax-std/BaseScript.sol";
import { FloxIncentivesDistributor } from "src/contracts/VestedFXS-and-Flox/Flox/FloxIncentivesDistributor.sol";
import { VestedFXS } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol";
import { VestedFXSUtils } from "src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { IveFXSStructs } from "src/contracts/VestedFXS-and-Flox/VestedFXS/IveFXSStructs.sol";

import { DeployVestedFXS } from "./DeployVestedFXS.s.sol";

contract DeployVeFXSDemo is BaseScript, IveFXSStructs {
    function run() external broadcaster {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        MintableBurnableTestERC20 token = new MintableBurnableTestERC20("mock FXS", "FXS");
        (VestedFXS vestedFXS, VestedFXSUtils vestedFXSUtils) = (new DeployVestedFXS()).runTest(
            address(token),
            "DemoVestedFXS"
        );
        FloxIncentivesDistributor floxIncentivesDistributor = new FloxIncentivesDistributor(
            address(vestedFXS),
            address(token)
        );

        token.mint(msg.sender, 1_000_000 * 1e18);
        token.mint(address(floxIncentivesDistributor), 1_000_000 * 1e18);
        token.approve(address(vestedFXS), 1_000_000 * 1e18);

        vestedFXS.setVeFXSUtils(address(vestedFXSUtils));
        vestedFXS.setFloxContributor(msg.sender, true);
        vestedFXS.setFloxContributor(address(floxIncentivesDistributor), true);
        floxIncentivesDistributor.addContributor(msg.sender);

        address bob = 0x9bCf7A9C00000000001816D9Cb3DF8878E221D97;

        console.log("Setup complete");
        console.log("Deployer's balance:", token.balanceOf(address(this)));
        console.log("Bob's balance:", token.balanceOf(bob));
        console.log("Distributor's balance:", token.balanceOf(address(floxIncentivesDistributor)));
        console.log("");

        (
            uint128 deployerLockNumber,
            uint128 bobLockNumber,
            uint256 deployerVotingPower,
            uint256 bobVotingPower
        ) = createLocks(vestedFXS, vestedFXSUtils, bob);

        address[] memory users = gettingUserlocks(vestedFXS, vestedFXSUtils, deployerLockNumber, bobLockNumber, bob);
        console.log("");
        (uint128 deployerLongestLockIndex, uint128 bobLongestLockIndex) = examineLongestLocks(
            vestedFXSUtils,
            bob,
            users
        );
        console.log("");

        bulkLockHandling(
            vestedFXS,
            vestedFXSUtils,
            floxIncentivesDistributor,
            bob,
            deployerLongestLockIndex,
            bobLongestLockIndex,
            deployerLockNumber,
            bobLockNumber,
            deployerVotingPower,
            bobVotingPower
        );
    }

    function createLocks(
        VestedFXS vestedFXS,
        VestedFXSUtils vestedFXSUtils,
        address bob
    ) public returns (uint128, uint128, uint256, uint256) {
        console.log("Creating locks for deployer");
        uint256 maxLockTimestamp = block.timestamp + (4 * 365 * 86_400);
        uint256 month = 30 * 86_400;
        uint256 lockAmount = 1000;
        vestedFXS.createLock(msg.sender, lockAmount, uint128(maxLockTimestamp));
        vestedFXS.createLock(msg.sender, lockAmount, uint128(maxLockTimestamp - month));
        vestedFXS.createLock(msg.sender, lockAmount, uint128(maxLockTimestamp - 2 * month));
        uint128 deployerLockNumber = vestedFXS.numLocks(msg.sender);
        console.log("Number of deployer's locks:", deployerLockNumber);
        console.log("");

        console.log("Creating locks for bob");
        vestedFXS.createLock(bob, lockAmount, uint128(maxLockTimestamp - 4 * month));
        vestedFXS.createLock(bob, lockAmount, uint128(maxLockTimestamp - 2 * month));
        uint128 bobLockNumber = vestedFXS.numLocks(bob);
        console.log("Number of bob's locks:", bobLockNumber);
        console.log("");

        console.log("Total voting power of all users:", vestedFXS.totalSupply(0));
        uint256 deployerVotingPower = vestedFXS.balanceOfAt(msg.sender, block.number);
        console.log("Deployer's voting power:", deployerVotingPower);
        uint256 bobVotingPower = vestedFXS.balanceOfAt(bob, block.number);
        console.log("Deployer's voting power:", bobVotingPower);
        console.log("");

        return (deployerLockNumber, bobLockNumber, deployerVotingPower, bobVotingPower);
    }

    function gettingUserlocks(
        VestedFXS vestedFXS,
        VestedFXSUtils vestedFXSUtils,
        uint128 deployerLockNumber,
        uint128 bobLockNumber,
        address bob
    ) public view returns (address[] memory) {
        console.log("Examining locks");
        console.log("Deployer's locks retrieved from utils:");

        DetailedUserLockInfo memory deployerLockInfo = vestedFXSUtils.getDetailedUserLockInfo(msg.sender);
        LockedBalanceExtended[] memory deployerLocks = deployerLockInfo.allLocks;
        for (uint256 i; i < deployerLockNumber; ) {
            console.log("Lock %s of %s is:", i, msg.sender);
            console.log("[");
            console.log("  amount:", uint128(deployerLocks[i].amount));
            console.log("  unlockTime:", deployerLocks[i].end);
            console.log("]");

            unchecked {
                ++i;
            }
        }
        console.log("Bob's locks retrieved from utils:");
        DetailedUserLockInfo memory bobLockInfo = vestedFXSUtils.getDetailedUserLockInfo(bob);
        LockedBalanceExtended[] memory bobLocks = bobLockInfo.allLocks;
        for (uint256 i; i < bobLockNumber; ) {
            console.log("Lock %s of %s is:", i, bob);
            console.log("[");
            console.log("  amount:", uint128(bobLocks[i].amount));
            console.log("  unlockTime:", bobLocks[i].end);
            console.log("]");

            unchecked {
                ++i;
            }
        }
        console.log("Getting locks of both users from utils:");
        address[] memory users = new address[](2);
        users[0] = msg.sender;
        users[1] = bob;
        DetailedUserLockInfo[] memory bulkLockInfos = new DetailedUserLockInfo[](users.length);
        for (uint256 i = 0; i < 2; ) {
            uint128 numberOfLocks = vestedFXS.numLocks(users[i]);
            LockedBalanceExtended[] memory locks = new LockedBalanceExtended[](numberOfLocks);

            DetailedUserLockInfo memory userLockInfo = vestedFXSUtils.getDetailedUserLockInfo(users[i]);
            locks = userLockInfo.allLocks;

            // Empty arrays
            int128[3] memory tmpArr;
            bulkLockInfos[i] = DetailedUserLockInfo({
                user: users[i],
                numberOfLocks: numberOfLocks,
                allLocks: locks,
                activeLocks: new LockedBalanceExtended[](numberOfLocks), // empty for now
                expiredLocks: new LockedBalanceExtended[](numberOfLocks), // empty for now
                totalFxs: tmpArr // empty for now
            });

            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < 2; ) {
            console.log("[");
            console.log("  [");
            for (uint256 j = 0; j < bulkLockInfos[i].numberOfLocks; ) {
                console.log("    [");
                console.log("      amount:", uint128(bulkLockInfos[i].allLocks[j].amount));
                console.log("      end:", bulkLockInfos[i].allLocks[j].end);
                if (j == bulkLockInfos[i].numberOfLocks - 1) {
                    console.log("    ]");
                } else {
                    console.log("    ],");
                }

                unchecked {
                    ++j;
                }
            }
            console.log("  ],");
            console.log("  numberOfLocks: %s,", bulkLockInfos[i].numberOfLocks);
            console.log("  user:", bulkLockInfos[i].user);

            if (i == 1) {
                console.log("]");
            } else {
                console.log("],");
            }

            unchecked {
                ++i;
            }
        }

        return users;
    }

    function examineLongestLocks(
        VestedFXSUtils vestedFXSUtils,
        address bob,
        address[] memory users
    ) public view returns (uint128, uint128) {
        console.log("Retrieving longest lock of deployer from utils:");
        LockedBalance memory deployerLongestLock;
        uint128 deployerLongestLockIndex;
        (deployerLongestLock, deployerLongestLockIndex) = vestedFXSUtils.getLongestLock(msg.sender);
        console.log("Longest lock of %s is:", msg.sender);
        console.log("[");
        console.log("  amount:", uint128(deployerLongestLock.amount));
        console.log("  unlockTime:", deployerLongestLock.end);
        console.log("]");
        console.log("Longest lock index is:", deployerLongestLockIndex);
        console.log("");

        console.log("Retrieving longest lock of bob from utils:");
        LockedBalance memory bobLongestLock;
        uint128 bobLongestLockIndex;
        (bobLongestLock, bobLongestLockIndex) = vestedFXSUtils.getLongestLock(bob);
        console.log("Longest lock of %s is:", bob);
        console.log("[");
        console.log("  amount:", uint128(bobLongestLock.amount));
        console.log("  unlockTime:", bobLongestLock.end);
        console.log("]");
        console.log("Longest lock index is:", bobLongestLockIndex);
        console.log("");

        console.log("Retrieving longest lock of both users from utils:");
        VestedFXSUtils.LongestLock[] memory longestLock = new VestedFXSUtils.LongestLock[](2);
        longestLock = vestedFXSUtils.getLongestLockBulk(users);
        console.log("Longest lock of both users are:");
        console.log("[");
        for (uint256 i = 0; i < 2; ) {
            console.log("  [");
            console.log("    amount: %s,", uint128(longestLock[i].lock.amount));
            console.log("    end:", longestLock[i].lock.end);
            console.log("  ],");
            console.log("  lockIndex: %s,", longestLock[i].lockIndex);
            console.log("  user:", longestLock[i].user);

            if (i == 1) {
                console.log("]");
            } else {
                console.log("],");
            }

            unchecked {
                ++i;
            }
        }

        return (deployerLongestLockIndex, bobLongestLockIndex);
    }

    function bulkLockHandling(
        VestedFXS vestedFXS,
        VestedFXSUtils vestedFXSUtils,
        FloxIncentivesDistributor floxIncentivesDistributor,
        address bob,
        uint128 deployerLongestLockIndex,
        uint128 bobLongestLockIndex,
        uint128 deployerLockNumber,
        uint128 bobLockNumber,
        uint256 deployerVotingPower,
        uint256 bobVotingPower
    ) public {
        console.log("Increasing value of locks through Flox incentives distributor");
        FloxIncentivesDistributor.IncentivesInput[]
            memory incentivesInput = new FloxIncentivesDistributor.IncentivesInput[](2);
        incentivesInput[0].recipient = msg.sender;
        incentivesInput[0].lockIndex = uint8(deployerLongestLockIndex);
        incentivesInput[0].amount = 50;
        incentivesInput[1].recipient = bob;
        incentivesInput[1].lockIndex = uint8(bobLongestLockIndex);
        incentivesInput[1].amount = 42;
        floxIncentivesDistributor.allocateIncentivesToExistingLocks(incentivesInput);

        console.log("Previous deployer's voting power:", deployerVotingPower);
        deployerVotingPower = vestedFXS.balanceOfAt(msg.sender, block.number);
        console.log("New deployer's voting power:", deployerVotingPower);
        console.log("Previous bob's voting power:", bobVotingPower);
        bobVotingPower = vestedFXS.balanceOfAt(bob, block.number);
        console.log("New bob's voting power:", bobVotingPower);
        console.log("");

        floxIncentivesDistributor.allocateIncentivesToNewLocks(incentivesInput);

        console.log("Previous deployer's voting power:", deployerVotingPower);
        deployerVotingPower = vestedFXS.balanceOfAt(msg.sender, block.number);
        console.log("New deployer's voting power:", deployerVotingPower);
        console.log("Previous bob's voting power:", bobVotingPower);
        bobVotingPower = vestedFXS.balanceOfAt(bob, block.number);
        console.log("New bob's voting power:", bobVotingPower);
        console.log("");

        console.log("Previous number of deployer's locks:", deployerLockNumber);
        deployerLockNumber = vestedFXS.numLocks(msg.sender);
        console.log("New number of deployer's locks:", deployerLockNumber);
        console.log("Previous number of bob's locks:", bobLockNumber);
        bobLockNumber = vestedFXS.numLocks(bob);
        console.log("New number of bob's locks:", bobLockNumber);
    }
}
