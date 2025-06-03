// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin-4/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin-4/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable } from "@openzeppelin-4/contracts/access/Ownable.sol";

contract MockERC20OwnedV2 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor(
        address _owner,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable() ERC20Permit(name_) {
        _transferOwnership(_owner);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
