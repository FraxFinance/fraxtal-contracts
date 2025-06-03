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
// ======================= PoolBalanceChecker =========================
// ====================================================================

import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";

/**
 * @title PoolBalanceChecker
 * @author Frax Finance
 * @notice The PoolBalanceChecker contract is used to retrieve the balances of collateral and LP tokens of pools.
 */
contract PoolBalanceChecker {
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
        result = new uint256[](tokens.length);

        for (uint256 i; i < tokens.length; ) {
            if (tokens[i] == address(0)) result[i] = poolAddress.balance;
            else result[i] = IERC20(tokens[i]).balanceOf(poolAddress);

            unchecked {
                ++i;
            }
        }

        totalLpSupply = IERC20(poolAddress).totalSupply();
    }
}
