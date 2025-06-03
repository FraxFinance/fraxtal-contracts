// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IPriceOracle
/// @notice Interface for a price oracle.
interface IPriceOracle {
    /// @notice returns the price.
    /// @param _token token to return the price for.
    /// @return _price price of the token.
    function getPrice(address _token) external view returns (uint256 _price);
}
