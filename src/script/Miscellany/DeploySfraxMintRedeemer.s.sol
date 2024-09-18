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

contract DeploySfraxMintRedeemer is BaseScript {
    // Addresses
    address frax;
    address sfrax;
    address fraxOracle;
    address sfraxOracle;
    address tempAdmin;
    address eventualAdmin;
    uint256 fee;
    uint256 initialVaultTknPrice;

    function run()
        public
        broadcaster
        returns (
            FraxtalERC4626MintRedeemer _mintRedeemer,
            ManualPriceOracle _fraxOracle,
            ManualPriceOracle _sfraxOracle
        )
    {
        // Initialize tempAdmin and eventualAdmin
        tempAdmin = msg.sender;

        if (vm.envBool("IS_PROD")) {
            // Prod deploy
            frax = Constants.FraxtalStandardProxies.FRAX_PROXY;
            sfrax = Constants.FraxtalStandardProxies.SFRAX_PROXY;
            fraxOracle = address(0);
            sfraxOracle = 0x1B680F4385f24420D264D78cab7C58365ED3F1FF;
            eventualAdmin = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
            fee = 0.0000001e18;
            initialVaultTknPrice = 1.0571e18;
        } else {
            // Test deploy
            eventualAdmin = address(0);
            fraxOracle = address(deployManualPriceOracle(tempAdmin, frax, 1e6));
            sfraxOracle = address(deployManualPriceOracle(tempAdmin, sfrax, 1.04e6));
            fee = 0.0000001e18;
            initialVaultTknPrice = 1.04e18;
        }

        // Print the timestamp
        console.log("<<< Timestamp: %s >>>", block.timestamp);

        // Set return variables
        _fraxOracle = ManualPriceOracle(fraxOracle);
        _sfraxOracle = ManualPriceOracle(sfraxOracle);

        // Set network string
        string memory network = vm.envString("NETWORK");

        // Deploy FraxtalERC4626MintRedeemer implementation and its' proxy
        FraxtalERC4626MintRedeemer implementation = new FraxtalERC4626MintRedeemer();
        Proxy proxy = new Proxy{ salt: bytes32("sFRAX12345") }(tempAdmin);

        // Upgrade proxy to implementation and call initialize
        bytes memory data = abi.encodeCall(
            implementation.initialize,
            (eventualAdmin, frax, sfrax, fraxOracle, sfraxOracle, fee, initialVaultTknPrice)
        );
        proxy.upgradeToAndCall({ _implementation: address(implementation), _data: data });

        // // Pass same arguments to implementation
        // implementation.initialize({
        //     _owner: eventualAdmin,
        //     _underlyingTkn: frax,
        //     _vaultTkn: sfrax,
        //     _underlyingOracle: address(_fraxOracle),
        //     _vaultOracle: address(_sfraxOracle)
        // });

        // Set proxy owner to ProxyAdmin
        console.log("<<< Changing Proxy Admin [DeploySfraxMintRedeemer] >>>");
        proxy.changeAdmin({ _admin: eventualAdmin });

        // Set the FraxtalERC4626MintRedeemer interface to the proxy (note: not needed - for testing clarity)
        console.log("<<< Setting FraxtalERC4626MintRedeemer [sFRAX] >>>");
        _mintRedeemer = FraxtalERC4626MintRedeemer(address(proxy));

        console.log("FraxtalERC4626MintRedeemer [sFRAX] (Proxy): ", address(proxy));
        console.log("FraxtalERC4626MintRedeemer [sFRAX] (Implementation): ", address(implementation));
    }

    function runTest(
        address _frax,
        address _sfrax
    ) external returns (FraxtalERC4626MintRedeemer, ManualPriceOracle, ManualPriceOracle) {
        frax = _frax;
        sfrax = _sfrax;
        return run();
    }
}
