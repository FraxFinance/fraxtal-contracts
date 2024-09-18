// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { ManualPriceOracle } from "src/contracts/Miscellany/ManualPriceOracle.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import "src/Constants.sol" as Constants;
import { Proxy } from "src/contracts/VestedFXS-and-Flox/VestedFXS/Proxy.sol";
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

contract DeploySfxEthMintRedeemer is BaseScript {
    // Addresses
    address wfrxEth;
    address sfrxEth;
    address wfrxEthOracle;
    address sfrxEthOracle;
    address tempAdmin;
    address eventualAdmin;
    uint256 fee;
    uint256 initialVaultTknPrice;

    function run()
        public
        broadcaster
        returns (
            FraxtalERC4626MintRedeemer _mintRedeemer,
            ManualPriceOracle _wfrxEthOracle,
            ManualPriceOracle _sfrxEthOracle
        )
    {
        // Initialize tempAdmin and eventualAdmin
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            wfrxEth = Constants.FraxtalStandardProxies.WFRXETH_PROXY;
            sfrxEth = Constants.FraxtalStandardProxies.SFRXETH_PROXY;
            wfrxEthOracle = address(0);
            sfrxEthOracle = 0xEE095b7d9191603126Da584a1179BB403a027c3A; // FraxtalERC4626TransportOracle, price in sfrxETH per frxETH
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            fee = 0.0000001e18;
            initialVaultTknPrice = 1.0935789505238e18;
        } else {
            // Test deploy
            eventualAdmin = address(0);
            wfrxEthOracle = address(deployManualPriceOracle(tempAdmin, wfrxEth, 1e6));
            sfrxEthOracle = address(deployManualPriceOracle(tempAdmin, sfrxEth, 1.0936e6));
            fee = 0.0000001e18;
            initialVaultTknPrice = 1.0936e6;
        }

        // Print the timestamp
        console.log("<<< Timestamp: %s >>>", block.timestamp);

        // Set return variables
        _wfrxEthOracle = ManualPriceOracle(wfrxEthOracle);
        _sfrxEthOracle = ManualPriceOracle(sfrxEthOracle);

        // Set network string
        string memory network = vm.envString("NETWORK");

        // Deploy FraxtalERC4626MintRedeemer implementation and its' proxy
        FraxtalERC4626MintRedeemer implementation = new FraxtalERC4626MintRedeemer();
        Proxy proxy = new Proxy{ salt: bytes32("sfrxETH1") }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(
            implementation.initialize,
            (eventualAdmin, wfrxEth, sfrxEth, wfrxEthOracle, sfrxEthOracle, fee, initialVaultTknPrice)
        );
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });

        // // Pass same arguments to implementation
        // implementation.initialize({
        //     _owner: eventualAdmin,
        //     _underlyingTkn: wfrxEth,
        //     _vaultTkn: sfrxEth,
        //     _underlyingOracle: address(_wfrxEthOracle),
        //     _vaultOracle: address(_sfrxEthOracle)
        // });

        // Set proxy owner to ProxyAdmin
        console.log("<<< Changing Proxy Admin [DeploySfxEthMintRedeemer] >>>");
        proxy.changeAdmin({ _admin: eventualAdmin });

        // Set the FraxtalERC4626MintRedeemer interface to the proxy (note: not needed - for testing clarity)
        console.log("<<< Setting FraxtalERC4626MintRedeemer [sfrxETH] >>>");
        _mintRedeemer = FraxtalERC4626MintRedeemer(address(proxy));

        console.log("FraxtalERC4626MintRedeemer [sfrxETH] (Proxy): ", address(proxy));
        console.log("FraxtalERC4626MintRedeemer [sfrxETH] (Implementation): ", address(implementation));
    }

    function runTest(
        address _wfrxEth,
        address _sfrxEth
    ) external returns (FraxtalERC4626MintRedeemer, ManualPriceOracle, ManualPriceOracle) {
        wfrxEth = _wfrxEth;
        sfrxEth = _sfrxEth;
        return run();
    }
}
