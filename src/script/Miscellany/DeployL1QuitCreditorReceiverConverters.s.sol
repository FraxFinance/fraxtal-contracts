// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import {
    L1QuitCreditorReceiverConverter
} from "src/contracts/Miscellany/FraxFarmQuitCreditor/L1QuitCreditorReceiverConverter.sol";
import "src/Constants.sol" as Constants;
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

contract DeployL1QuitCreditorReceiverConverters is BaseScript {
    // Deploy variables
    address owner;
    address quitCreditorFRAXDAI;
    address quitCreditorFRAXUSDC;
    address conversionToken;
    uint256 conversionPrice;

    function run()
        public
        broadcaster
        returns (
            L1QuitCreditorReceiverConverter _fxtlL1QuitCdRecCvtrAddrFRAXDAI,
            L1QuitCreditorReceiverConverter _fxtlL1QuitCdRecCvtrAddrFRAXUSDC
        )
    {
        if (vm.envBool("IS_PROD")) {
            // L1QuitCreditorReceiverConverterFRAXDAI: 0x022A613950D36F9034D7B883fE5017B27e3d131d
            // L1QuitCreditorReceiverConverterFRAXUSDC: 0x21834a083484D6bAbF9Da1179f8a87eC9E03811A

            // Prod deploy
            owner = Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG;
            quitCreditorFRAXDAI = address(0x2b5C6EfC86d09726608AfE54FB2eE3e6F3c54162);
            quitCreditorFRAXUSDC = address(0x9E461cF6773F168A991A7aD73E2aD89ecD737745);
            conversionToken = Constants.FraxtalMainnet.FXB_20291231;
            conversionPrice = 0.794e18;
        } else {
            // Test deploy
            owner = msg.sender; // TODO: Fix later
            quitCreditorFRAXDAI = address(0);
            quitCreditorFRAXUSDC = address(0);
            conversionToken = Constants.FraxtalMainnet.FXB_20291231;
            conversionPrice = 0.794e18;
        }

        // Deploy L1QuitCreditorReceiverConverter FRAX/DAI
        _fxtlL1QuitCdRecCvtrAddrFRAXDAI = new L1QuitCreditorReceiverConverter({
            _owner: owner,
            _quitCreditor: quitCreditorFRAXDAI,
            _conversionToken: conversionToken,
            _conversionPrice: conversionPrice
        });

        // Deploy L1QuitCreditorReceiverConverter FRAX/USDC
        _fxtlL1QuitCdRecCvtrAddrFRAXUSDC = new L1QuitCreditorReceiverConverter({
            _owner: owner,
            _quitCreditor: quitCreditorFRAXUSDC,
            _conversionToken: conversionToken,
            _conversionPrice: conversionPrice
        });

        console.log("======== ADDRESSES ======== ");
        console.log("L1QuitCreditorReceiverConverter FRAX/DAI: ", address(_fxtlL1QuitCdRecCvtrAddrFRAXDAI));
        console.log("L1QuitCreditorReceiverConverter FRAX/USDC: ", address(_fxtlL1QuitCdRecCvtrAddrFRAXUSDC));
    }

    function runTest() external returns (L1QuitCreditorReceiverConverter, L1QuitCreditorReceiverConverter) {
        return run();
    }
}
