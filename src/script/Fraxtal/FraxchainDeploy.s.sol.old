// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";
import "src/Constants.sol" as Constants;

contract FraxchainDeploy is BaseScript {
    string internal network;

    function setUp() public virtual override {
        BaseScript.setUp();
        network = vm.envString("NETWORK");

        if (
            !Strings.equal(network, Constants.FraxtalDeployment.DEVNET) &&
            !Strings.equal(network, Constants.FraxtalDeployment.TESTNET) &&
            !Strings.equal(network, Constants.FraxtalDeployment.MAINNET) &&
            !Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)
        ) {
            revert("NETWORK env variable must be either 'devnet' or 'testnet' or 'mainnet' or 'testnet-sepolia'");
        }
    }
}
