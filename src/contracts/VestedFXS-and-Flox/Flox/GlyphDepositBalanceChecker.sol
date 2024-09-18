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
// ================== GlyphDepositBalanceChecker ======================
// ====================================================================

interface IGlyphToken {
    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

/**
 * @title GlyphDepositBalanceChecker
 * @author Frax Finance
 * @notice The GlyphDepositBalanceChecker contract is used to retrieve the balances of addresses and tokens.
 */
contract GlyphDepositBalanceChecker {
    mapping(address glyphToken => address fraxToken) private glyphToFraxToken;

    constructor() {
        glyphToFraxToken[0x5E76562a265Aa595AD7377b11d17Cb0237970F20] = 0xFc00000000000000000000000000000000000001; // glyphFRAX => FRAX
        glyphToFraxToken[0x6D24Bfa1A4F68fA62dD7989D8961d1F0C251dC69] = 0xFC00000000000000000000000000000000000006; // glyphfrxETH => wfrxETH
        glyphToFraxToken[0x471e51c7DAA092c07d1Fd75BAE492f3d76813620] = 0xFc00000000000000000000000000000000000002; // glyphFXS => FXS
        glyphToFraxToken[0xa6DD2773131e040e62E5a37482337536d7d00FB3] = 0xFC00000000000000000000000000000000000005; // glyphsfrxETH => sfrxETH
        glyphToFraxToken[0xF70b678FA8779F406D0e608B77E2290a8b4ff123] = 0xfc00000000000000000000000000000000000008; // glyphsFRAX => sFRAX
    }

    /**
     * @notice Used to get the token's balance for multiple addresses.
     * @param token Address of the token to check the balance of
     * @param addresses An array of addresses to check the balance of
     * @return result An array of the balances of the addresses
     */
    function tokenBalances(address token, address[] memory addresses) external view returns (uint256[] memory result) {
        result = new uint256[](addresses.length);
        IGlyphToken glyphToken = IGlyphToken(token);
        IGlyphToken fraxToken = IGlyphToken(glyphToFraxToken[token]);

        uint256 glyphTotalSupply = glyphToken.totalSupply();
        uint256 glyphFraxBalance = fraxToken.balanceOf(token);

        for (uint256 i = 0; i < addresses.length; ++i) {
            result[i] = (glyphToken.balanceOf(addresses[i]) * glyphFraxBalance) / glyphTotalSupply;
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
