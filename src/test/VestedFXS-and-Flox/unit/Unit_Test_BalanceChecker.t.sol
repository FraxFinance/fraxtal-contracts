// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { BalanceChecker } from "src/contracts/VestedFXS-and-Flox/Flox/BalanceChecker.sol";
import { MintableERC20 } from "../helpers/MintableERC20.sol";
import "forge-std/console.sol";

contract Unit_Test_BalanceChecker is BaseTestVeFXS {
    using stdStorage for StdStorage;

    BalanceChecker public registry;

    function setUp() public {
        defaultSetup();

        registry = new BalanceChecker();
    }

    function test_TokenBalances() public {
        MintableERC20 token = new MintableERC20("Test Token", "TST");
        token.mint(address(bob), 42e20);
        token.mint(alice, 42e18);

        address[] memory addresses = new address[](2);
        addresses[0] = bob;
        addresses[1] = alice;

        uint256[] memory balances = registry.tokenBalances(address(token), addresses);
        assertEq(balances[0], 42e20);
        assertEq(balances[1], 42e18);

        bob.call{ value: 42e19 }("");
        alice.call{ value: 42e21 }("");

        balances = registry.tokenBalances(address(0), addresses);
        assertEq(balances[0], 42e19);
        assertEq(balances[1], 42e21);
    }

    function test_AddressBalances() public {
        MintableERC20 token0 = new MintableERC20("Test Token", "TST");
        MintableERC20 token1 = new MintableERC20("Test Token", "TST");
        MintableERC20 token2 = new MintableERC20("Test Token", "TST");

        token0.mint(address(bob), 42e20);
        token1.mint(address(bob), 42e18);
        token2.mint(address(bob), 42e16);
        token0.mint(alice, 42e16);
        token1.mint(alice, 42e18);
        token2.mint(alice, 42e20);

        bob.call{ value: 42e19 }("");
        alice.call{ value: 42e21 }("");

        address[] memory tokens = new address[](4);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);
        tokens[3] = address(0);

        uint256[] memory balances = registry.addressBalances(bob, tokens);
        assertEq(balances[0], 42e20);
        assertEq(balances[1], 42e18);
        assertEq(balances[2], 42e16);
        assertEq(balances[3], 42e19);

        balances = registry.addressBalances(alice, tokens);
        assertEq(balances[0], 42e16);
        assertEq(balances[1], 42e18);
        assertEq(balances[2], 42e20);
        assertEq(balances[3], 42e21);
    }
}
