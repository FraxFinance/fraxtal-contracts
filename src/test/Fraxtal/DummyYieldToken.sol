// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyYieldToken is ERC20 {
    uint256 public pricePerShare = 1e18;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 100_000_000e18); // Genesis mint
    }

    function convertToShares(uint256 _amount) external view returns (uint256 _shares) {
        _shares = (_amount * 1e18) / pricePerShare;
    }

    function convertToAssets(uint256 _amount) external view returns (uint256 _assets) {
        _assets = (_amount * pricePerShare) / 1e18;
    }

    function setPricePerShare(uint256 _pricePerShare) external {
        pricePerShare = _pricePerShare;
    }
}
