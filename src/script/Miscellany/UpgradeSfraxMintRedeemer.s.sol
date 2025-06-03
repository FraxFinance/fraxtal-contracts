// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { ManualPriceOracle } from "src/contracts/Miscellany/ManualPriceOracle.sol";
import "src/Constants.sol" as Constants;

import { Proxy } from "./Proxy.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";

function deployManualPriceOracle(
    address _owner,
    address _tknAddress,
    uint256 _initialPriceE6
) returns (ManualPriceOracle _oracle) {
    _oracle = new ManualPriceOracle({
        _creator_address: _owner,
        _tkn_address: _tknAddress,
        _timelock_address: _owner,
        _bot_address: _owner,
        _initial_price_e6: _initialPriceE6,
        _decimals: 18,
        _description: ""
    });
}

function deployNewMintRedeemerImpl() returns (FraxtalERC4626MintRedeemer _mintRedeemerImpl) {
    _mintRedeemerImpl = new FraxtalERC4626MintRedeemer();
}

contract UpgradeSfraxMintRedeemer is BaseScript {
    // Addresses
    address frax;
    address sfrax;
    address fraxOracle;
    address sfraxOracle;
    address tempAdmin;
    address eventualAdmin;
    uint256 fee;
    uint256 initialVaultTknPrice;
    address sFraxMintRedeemerProxy = 0xBFc4D34Db83553725eC6c768da71D2D9c1456B55;

    function run() public broadcaster returns (FraxtalERC4626MintRedeemer _implementation) {
        // Initialize the network
        string memory network = vm.envString("NETWORK");

        // Will be overwritten for prod deploy
        eventualAdmin = msg.sender;
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            // frax = Constants.FraxtalStandardProxies.FRAX_PROXY;
            // sfrax = Constants.FraxtalStandardProxies.SFRAX_PROXY;
            // fraxOracle = address(0);
            // sfraxOracle = 0x1B680F4385f24420D264D78cab7C58365ED3F1FF;
            // eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            // fee = 0.0000001e18;
            // initialVaultTknPrice = 1_102_220_872_978_697_594;
            frax = address(0);
            sfrax = address(0);
            fraxOracle = address(0);
            sfraxOracle = address(0);
            eventualAdmin = address(0);
            fee = 0;
            initialVaultTknPrice = 0;
        } else {
            // Test deploy
            // Will be filled in from runTest
            // // Test deploy
            // fraxOracle = address(deployManualPriceOracle(tempAdmin, frax, 1e6));
            // sfraxOracle = address(deployManualPriceOracle(tempAdmin, sfrax, 1e6));
            // fee = 0.0000001e18;
            // initialVaultTknPrice = 1e18;
        }

        // Deploy the new FraxtalERC4626MintRedeemer implementation
        _implementation = deployNewMintRedeemerImpl();

        // Initialize the implementation
        _implementation.initialize({
            _owner: eventualAdmin,
            _underlyingTkn: frax,
            _vaultTkn: sfrax,
            _underlyingOracle: fraxOracle,
            _vaultOracle: sfraxOracle,
            _fee: fee,
            _initialVaultTknPrice: initialVaultTknPrice
        });

        console.log("Current FraxtalERC4626MintRedeemer proxy: ", address(sFraxMintRedeemerProxy));
        console.log("New FraxtalERC4626MintRedeemer implementation: ", address(_implementation));
        // console.log("============== DATA ==============");
        // console.logBytes(data);
        // console.log("==================================");

        // DO THIS MANUALLY WITH THE COMPTROLLER
        console.log("NEED TO DO sFraxMintRedeemerProxy.upgradeTo WITH COMPTROLLER!!!");
        console.log("NEED TO DO sFraxMintRedeemerProxy.upgradeTo WITH COMPTROLLER!!!");
        console.log("NEED TO DO sFraxMintRedeemerProxy.upgradeTo WITH COMPTROLLER!!!");
        // sFraxMintRedeemerProxy.upgradeTo({ _implementation: address(implementation)});
    }

    function runTest(
        address _frax,
        address _sfrax,
        address _fraxOracle,
        address _sfraxOracle,
        address _eventualAdmin,
        uint256 _fee,
        uint256 _initialVaultTknPrice
    ) external returns (FraxtalERC4626MintRedeemer) {
        frax = _frax;
        sfrax = _sfrax;
        fraxOracle = _fraxOracle;
        sfraxOracle = _sfraxOracle;
        eventualAdmin = _eventualAdmin;
        fee = _fee;
        initialVaultTknPrice = _initialVaultTknPrice;
        return run();
    }
}
