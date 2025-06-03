// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC4626 } from "@openzeppelin-4/contracts/interfaces/IERC4626.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";

/// @title ERC4626PriceOracle
/// @notice Price oracle for ERC4626 compatible tokens.
contract ERC4626PriceOracle is IPriceOracle {
    /// @notice returns the price.
    /// @param _token token to return the price for.
    /// @return _price price of the token.
    function getPrice(address _token) external view returns (uint256 _price) {
        return IERC4626(_token).convertToAssets(1e18);
    }
}
