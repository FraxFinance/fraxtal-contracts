// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";

interface IBalancerVault {
    function getPoolTokenInfo(
        bytes32 poolId,
        IERC20 token
    ) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);
}
