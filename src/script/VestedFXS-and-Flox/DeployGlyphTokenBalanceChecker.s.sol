// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import { GlyphDepositBalanceChecker } from "src/contracts/VestedFXS-and-Flox/Flox/GlyphDepositBalanceChecker.sol";

function deployDepositBalanceChecker() returns (address) {
    GlyphDepositBalanceChecker depositBalanceChecker = new GlyphDepositBalanceChecker();

    return address(depositBalanceChecker);
}

contract DeployFraxswapBalanceCheckers is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        address depositBalanceChecker = deployDepositBalanceChecker();
        console.log("GlyphDepositBalanceChecker deployed at: ", depositBalanceChecker);

        vm.stopBroadcast();
    }
}
