// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =================== BalancerPoolBalanceChecker =====================
// ====================================================================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBalancerPool } from "./interfaces/IBalancerPool.sol";
import { IBalancerVault } from "./interfaces/IBalancerVault.sol";

/**
 * @title BalancerPoolBalanceChecker
 * @author Frax Finance
 * @notice The BalancerPoolBalanceChecker contract is used to retrieve the balances of collateral and LP tokens of pools.
 */
contract BalancerPoolBalanceChecker {
    IBalancerVault private balancerVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    constructor() {}

    /**
     * @notice Used to get the structure of a pool.
     * @dev Passing `0x0` address as the token address gets the native token balance.
     * @param poolAddress Address of the pool to check the structure of
     * @param tokens An array of tokens to check the balance of
     * @return result An array of the balances of the tokens in the pool
     * @return totalLpSupply The total supply of the LP token
     */
    function poolStructure(
        address poolAddress,
        address[] memory tokens
    ) external view returns (uint256[] memory result, uint256 totalLpSupply) {
        bytes32 poolId = 0xa0b92b33beafce388ce0092afdcd0ca77323eb12000000000000000000000006;
        result = new uint256[](tokens.length);

        for (uint256 i; i < tokens.length; ) {
            (uint256 balance, , , ) = balancerVault.getPoolTokenInfo(poolId, IERC20(tokens[i]));
            result[i] = balance;

            unchecked {
                ++i;
            }
        }

        totalLpSupply = IBalancerPool(poolAddress).getActualSupply();
    }
}
