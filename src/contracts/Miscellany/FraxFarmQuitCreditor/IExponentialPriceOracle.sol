// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IExponentialPriceOracle {
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function priceEnd() external view returns (uint256);

    function pricePerShare() external view returns (uint256 _price);

    function priceStart() external view returns (uint256);

    function timeEnd() external view returns (uint256);

    function timeStart() external view returns (uint256);
}
