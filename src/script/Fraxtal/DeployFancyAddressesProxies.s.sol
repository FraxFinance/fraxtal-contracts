// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "frax-std/FraxTest.sol";
import { Strings } from "@openzeppelin-4/contracts/utils/Strings.sol";
import { ProxyAdmin } from "@openzeppelin-4/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy
} from "@openzeppelin-4/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { FraxchainDeploy } from "./FraxchainDeploy.s.sol";
import "src/Constants.sol" as Constants;

contract Dummy {}

contract DeployFancyAddressesProxies is FraxchainDeploy {
    address _admin;
    address _proxyAdmin;

    function run() external broadcaster returns (string memory) {
        if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
            _admin = Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN;
            _proxyAdmin = Constants.FraxtalL2Devnet.PROXY_ADMIN;
        } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
            _admin = Constants.FraxtalTestnet.FRAXCHAIN_ADMIN;
            _proxyAdmin = Constants.FraxtalTestnet.PROXY_ADMIN;
        } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
            _admin = Constants.FraxtalMainnet.FRAXCHAIN_ADMIN;
            _proxyAdmin = Constants.FraxtalMainnet.PROXY_ADMIN;
        } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
            _admin = Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN;
            _proxyAdmin = Constants.FraxtalTestnetSepolia.PROXY_ADMIN;
        } else {
            revert("Unsupported network");
        }

        ProxyAdmin proxyAdmin = new ProxyAdmin();
        proxyAdmin.transferOwnership(_admin);
        Dummy dummy = new Dummy();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(dummy), _proxyAdmin, "");

        string memory _json = "";
        _json = stdJson.serialize("", "ProxyAdmin", address(proxyAdmin));
        _json = stdJson.serialize("", "Proxy", address(proxy));
        _json = stdJson.serialize("", "admin", Strings.toHexString(uint256(uint160(address(_admin))), 32));

        return _json;
    }
}
