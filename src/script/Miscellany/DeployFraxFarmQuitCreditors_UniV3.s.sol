// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import {
    FraxFarmQuitCreditor_UniV3
} from "src/contracts/Miscellany/FraxFarmQuitCreditor/FraxFarmQuitCreditor_UniV3.sol";
import "src/Constants.sol" as Constants;
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

contract DeployFraxFarmQuitCreditors_UniV3 is BaseScript {
    // Deploy variables
    address owner;
    address fxtlL1QuitCdRecCvtrAddrFRAXDAI;
    address fxtlL1QuitCdRecCvtrAddrFRAXUSDC;

    function run()
        public
        broadcaster
        returns (FraxFarmQuitCreditor_UniV3 _quitCreditorFRAXDAI, FraxFarmQuitCreditor_UniV3 _quitCreditorFRAXUSDC)
    {
        if (vm.envBool("IS_PROD")) {
            // FraxFarmQuitCreditor_UniV3 FRAX/DAI: 0x2b5C6EfC86d09726608AfE54FB2eE3e6F3c54162
            // FraxFarmQuitCreditor_UniV3 FRAX/USDC: XXXXXX

            // Prod deploy
            owner = Constants.Mainnet.MAIN_MAINNET_COMPTROLLER;
            fxtlL1QuitCdRecCvtrAddrFRAXDAI = address(0); // Will be set later
            fxtlL1QuitCdRecCvtrAddrFRAXUSDC = address(0); // Will be set later
        } else {
            // Test deploy
            owner = msg.sender;
            fxtlL1QuitCdRecCvtrAddrFRAXDAI = address(0); // Will be set later
            fxtlL1QuitCdRecCvtrAddrFRAXUSDC = address(0); // Will be set later
        }

        // Deploy FraxFarmQuitCreditor_UniV3 FRAX/DAI
        console.log("Deploy FraxFarmQuitCreditor_UniV3 FRAX/DAI");
        _quitCreditorFRAXDAI = new FraxFarmQuitCreditor_UniV3({
            _owner: owner,
            _fxtlL1QuitCdRecCvtrAddr: fxtlL1QuitCdRecCvtrAddrFRAXDAI,
            _farm: address(0xF22471AC2156B489CC4a59092c56713F813ff53e)
        });

        // Deploy FraxFarmQuitCreditor_UniV3 FRAX/USDC
        console.log("Deploy FraxFarmQuitCreditor_UniV3 FRAX/USDC");
        _quitCreditorFRAXUSDC = new FraxFarmQuitCreditor_UniV3({
            _owner: owner,
            _fxtlL1QuitCdRecCvtrAddr: fxtlL1QuitCdRecCvtrAddrFRAXUSDC,
            _farm: address(0x3EF26504dbc8Dd7B7aa3E97Bc9f3813a9FC0B4B0)
        });

        console.log("======== ADDRESSES ======== ");
        console.log("FraxFarmQuitCreditor_UniV3 FRAX/DAI: ", address(_quitCreditorFRAXDAI));
        console.log("FraxFarmQuitCreditor_UniV3 FRAX/USDC: ", address(_quitCreditorFRAXUSDC));
    }

    function runTest() external returns (FraxFarmQuitCreditor_UniV3, FraxFarmQuitCreditor_UniV3) {
        return run();
    }
}
