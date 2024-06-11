//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {
    OptimismMintablePermitERC20Factory
} from "src/contracts/Fraxtal/universal/OptimismMintablePermitERC20Factory.sol";
import "./FraxchainDeploy.s.sol";

contract DeployOptimismMintablePermitERC20Factory is FraxchainDeploy {
    function run() public broadcaster {
        new OptimismMintablePermitERC20Factory();
    }
}
