// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { stdJson } from "forge-std/StdJson.sol";
import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { Strings } from "@openzeppelin-4/contracts/utils/Strings.sol";
import { ProxyAdmin } from "@openzeppelin-4/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin-4/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/Constants.sol" as Constants;

contract Dummy {
    function get() external pure returns (uint256) {
        return 123;
    }
}

/// @dev Simple test script to ensure upgradeable proxy is workinng as intended.
contract TestProxyAdmin is BaseScript {
    function run() external broadcaster {
        Dummy dummy = new Dummy();
        dummy.get();
        ProxyAdmin admin = ProxyAdmin(0xfC00000000000000000000000000000000000007);
        admin.owner();
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(payable(0xfc00000000000000000000000000000000000008));
        admin.upgrade(proxy, address(dummy));
        Dummy dummyProxy = Dummy(payable(0xfc00000000000000000000000000000000000008));

        require(dummyProxy.get() == 123, "Upgraded proxy returned wrong value");
    }
}
