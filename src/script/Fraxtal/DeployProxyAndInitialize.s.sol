// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { Proxy } from "@eth-optimism/contracts-bedrock/src/universal/Proxy.sol";
import { BaseScript } from "frax-std/BaseScript.sol";
import "src/Constants.sol" as Constants;

/// @dev Assumes that _owner is msg.sender
function deployProxyAndInitialize(
    address _owner,
    address _implementation,
    bytes memory _data
) returns (Proxy iProxy, address proxy) {
    iProxy = new Proxy(_owner);
    proxy = address(iProxy);

    iProxy.upgradeToAndCall({ _implementation: _implementation, _data: _data });
}