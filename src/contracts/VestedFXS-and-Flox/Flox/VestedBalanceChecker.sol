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
// ====================== VestedBalanceChecker ========================
// ====================================================================

interface IVestedFXS {
    function balanceOfLockedFxs(address _addr) external view returns (uint256 _balanceOfLockedFxs);
}

interface IVestedFPIS {
    function balanceOfLockedFpis(address _addr) external view returns (uint256 _balanceOfLockedFpis);
}

/**
 * @title VestedBalanceChecker
 * @author Frax Finance
 * @notice The VestedBalanceChecker contract is used to retrieve the balances of addresses and tokens.
 */
contract VestedBalanceChecker {
    address public constant VEFXS = 0x007FD070a7E1B0fA1364044a373Ac1339bAD89CF;
    address public constant VEFPIS = 0x437E9F65cA234eCfed12149109587139d435AD35;

    constructor() {}

    /**
     * @notice Used to get the token's balance for multiple addresses.
     * @param token Address of the token to check the balance of
     * @param addresses An array of addresses to check the balance of
     * @return result An array of the balances of the addresses
     */
    function tokenBalances(address token, address[] memory addresses) external view returns (uint256[] memory result) {
        result = new uint256[](addresses.length);

        if (token == VEFXS) {
            IVestedFXS veFXS = IVestedFXS(token);
            for (uint256 i = 0; i < addresses.length; ++i) {
                result[i] = veFXS.balanceOfLockedFxs(addresses[i]);
            }
        } else if (token == VEFPIS) {
            IVestedFPIS veFPIS = IVestedFPIS(token);
            for (uint256 i = 0; i < addresses.length; ++i) {
                result[i] = veFPIS.balanceOfLockedFpis(addresses[i]);
            }
        }
    }
}
