// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestMisc } from "../BaseTestMisc.t.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { OwnedV2AutoMsgSender } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol";
import { console } from "frax-std/FraxTest.sol";
import "forge-std/console2.sol";

contract Fuzz_Test_sFRAXRedeemer is BaseTestMisc {
    function sFraxRedeemerSetup() public {
        console.log("sFraxRedeemerSetup() called");
        super.defaultSetup();

        // Mint FRAX to test users
        frax.mint(alice, 1000e18);
        frax.mint(bob, 1000e18);

        // Mint sFRAX to test users
        sfrax.mint(alice, 1000e18);
        sfrax.mint(bob, 1000e18);
    }
}
