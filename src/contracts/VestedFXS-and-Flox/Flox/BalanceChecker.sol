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
// ========================= BalanceChecker ===========================
// ====================================================================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BalanceChecker
 * @author Frax Finance
 * @notice The BalanceChecker contract is used to retrieve the balances of addresses and tokens.
 */
contract BalanceChecker {
    constructor() {}

    /**
     * @notice Used to get the token's balance for multiple addresses.
     * @dev Passing `0x0` address as the token address gets the native token balance.
     * @param token Address of the token to check the balance of
     * @param addresses An array of addresses to check the balance of
     * @return result An array of the balances of the addresses
     */
    function tokenBalances(address token, address[] memory addresses) external view returns (uint256[] memory result) {
        result = new uint256[](addresses.length);

        if (token == address(0)) {
            for (uint256 i = 0; i < addresses.length; ++i) {
                result[i] = addresses[i].balance;
            }
            return result;
        }

        IERC20 erc20 = IERC20(token);
        for (uint256 i = 0; i < addresses.length; ++i) {
            result[i] = erc20.balanceOf(addresses[i]);
        }
    }

    /**
     * @notice Used to get the balances of multiple tokens for a single address.
     * @dev Passing `0x0` address as the token address gets the native token balance.
     * @param addr Address to check the balance of
     * @param tokens An array of tokens to check the balance of
     * @return result An array of the balances of the tokens
     */
    function addressBalances(address addr, address[] memory tokens) external view returns (uint256[] memory result) {
        result = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            if (tokens[i] == address(0)) result[i] = addr.balance;
            else result[i] = IERC20(tokens[i]).balanceOf(addr);
        }
    }
}
