// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { stdJson } from "forge-std/StdJson.sol";
import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { Multicall3 } from "src/contracts/Fraxtal/L2/Multicall3.sol";
import { SystemConfig } from "@eth-optimism/contracts-bedrock/src/L1/SystemConfig.sol";
import { ResourceMetering } from "@eth-optimism/contracts-bedrock/src/L1/ResourceMetering.sol";
import { L2OutputOracle } from "@eth-optimism/contracts-bedrock/src/L1/L2OutputOracle.sol";
import "src/Constants.sol" as Constants;

function deployMulticall3() returns (Multicall3 _multicall3, address _address) {
    _multicall3 = new Multicall3();
    _address = address(_multicall3);
}

contract DeployMulticall3 is BaseScript {
    function run() external broadcaster returns (string memory) {
        address _address;
        (, _address) = deployMulticall3();

        string memory _json = "";
        _json = stdJson.serialize("", "Multicall3", _address);

        return _json;
    }
}
