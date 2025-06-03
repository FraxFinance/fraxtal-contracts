// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin-4/contracts/access/Ownable.sol";

contract GasToken is ERC20, Ownable {
    constructor() ERC20("Gas", "GAS") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
