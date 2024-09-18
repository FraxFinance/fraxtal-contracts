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
// ================= FraxswapDepositBalanceChecker ====================
// ====================================================================

import { IFraxlendPair } from "./interfaces/IFraxlendPair.sol";

/**
 * @title FraxswapDepositBalanceChecker
 * @author Frax Finance
 * @notice The FraxswapDepositBalanceChecker contract is used to retrieve the balances of addresses and tokens.
 */
contract FraxswapDepositBalanceChecker {
    constructor() {}

    /**
     * @notice Used to get the token's balance for multiple addresses.
     * @param token Address of the token to check the balance of
     * @param addresses An array of addresses to check the balance of
     * @return result An array of the balances of the addresses
     */
    function tokenBalances(address token, address[] memory addresses) external view returns (uint256[] memory result) {
        result = new uint256[](addresses.length);
        IFraxlendPair fraxlendPair = IFraxlendPair(token);
        (uint128 totalAssets, uint128 totalAssetShares, uint128 totalBorrowedAssets, , ) = fraxlendPair
            .getPairAccounting();

        uint256 totalUnborrowedAssets = uint256(totalAssets - totalBorrowedAssets);
        uint256 totalAssetSharesUint256 = uint256(totalAssetShares);

        for (uint256 i = 0; i < addresses.length; ++i) {
            (uint256 addressShares, , ) = fraxlendPair.getUserSnapshot(addresses[i]);

            result[i] = (totalUnborrowedAssets * addressShares) / totalAssetSharesUint256;
        }
    }

    /**
     * @notice Used to get the balances of multiple tokens for a single address.
     * @dev This function is only preserved for teh smart contract to maintain the same interface as the original
     *  BalanceChecker, but should not be called as it is hardcoded to simply return an empty array.
     * @param addr Address to check the balance of
     * @param tokens An array of tokens to check the balance of
     * @return result An array of the balances of the tokens
     */
    function addressBalances(address addr, address[] memory tokens) external view returns (uint256[] memory result) {
        uint256[] memory mockReturnValue;

        return mockReturnValue;
    }
}
