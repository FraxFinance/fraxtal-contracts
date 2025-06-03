// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-4/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @notice Mintable ERC20 token used to faciltae testing
/// @dev MUST not use in production because of exposed non-gated mint function
contract MintableBurnableTestERC20 is ERC20, ERC20Burnable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) { }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
