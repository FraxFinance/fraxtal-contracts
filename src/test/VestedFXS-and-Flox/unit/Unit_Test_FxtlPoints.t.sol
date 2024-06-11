// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestVeFXS } from "../BaseTestVeFXS.t.sol";
import { FxtlPoints } from "src/contracts/VestedFXS-and-Flox/Flox/FxtlPoints.sol";
import { OwnedV2 } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2.sol";

contract Unit_Test_FxtlPoints is BaseTestVeFXS {
    FxtlPoints fxtlPoints;

    event FxtlContributorAdded(address indexed contributor);
    event FxtlContributorRemoved(address indexed contributor);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        defaultSetup();

        fxtlPoints = new FxtlPoints();
    }

    function test_Name() public {
        assertEq(fxtlPoints.name(), "FXTL Points");
    }

    function test_Symbol() public {
        assertEq(fxtlPoints.symbol(), "FXTL");
    }

    function test_Decimals() public {
        assertEq(fxtlPoints.decimals(), 0);
    }

    function test_AddFxtlContributor() public {
        assertFalse(fxtlPoints.isFxtlContributor(bob));

        vm.expectEmit(true, false, false, true);
        emit FxtlContributorAdded(bob);
        fxtlPoints.addFxtlContributor(bob);

        assertTrue(fxtlPoints.isFxtlContributor(bob));

        vm.expectRevert(FxtlPoints.AlreadyFxtlContributor.selector);
        fxtlPoints.addFxtlContributor(bob);

        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        hoax(alice);
        fxtlPoints.addFxtlContributor(bob);
    }

    function test_RemoveFxtlContributor() public {
        vm.expectRevert(FxtlPoints.NotFxtlContributor.selector);
        fxtlPoints.removeFxtlContributor(bob);

        fxtlPoints.addFxtlContributor(bob);

        assertTrue(fxtlPoints.isFxtlContributor(bob));

        vm.expectRevert(OwnedV2.OnlyOwner.selector);
        hoax(alice);
        fxtlPoints.removeFxtlContributor(bob);

        vm.expectEmit(true, false, false, true);
        emit FxtlContributorRemoved(bob);
        fxtlPoints.removeFxtlContributor(bob);

        assertFalse(fxtlPoints.isFxtlContributor(bob));
    }

    function test_AddFxtlPoints() public {
        fxtlPoints.addFxtlContributor(bob);

        assertEq(fxtlPoints.balanceOf(alice), 0);
        assertEq(fxtlPoints.totalSupply(), 0);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 100);
        hoax(bob);
        fxtlPoints.addFxtlPoints(alice, 100);

        assertEq(fxtlPoints.balanceOf(alice), 100);
        assertEq(fxtlPoints.totalSupply(), 100);

        vm.expectRevert(FxtlPoints.NotFxtlContributor.selector);
        fxtlPoints.addFxtlPoints(alice, 100);
    }

    function test_RemoveFxtlPoints() public {
        fxtlPoints.addFxtlContributor(bob);
        hoax(bob);
        fxtlPoints.addFxtlPoints(alice, 100);

        assertEq(fxtlPoints.balanceOf(alice), 100);
        assertEq(fxtlPoints.totalSupply(), 100);

        vm.expectRevert(FxtlPoints.NotFxtlContributor.selector);
        fxtlPoints.removeFxtlPoints(alice, 100);

        vm.expectRevert(abi.encodeWithSelector(FxtlPoints.InsufficientFxtlPoints.selector, 100, 1000));
        hoax(bob);
        fxtlPoints.removeFxtlPoints(alice, 1000);

        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, address(0), 80);
        hoax(bob);
        fxtlPoints.removeFxtlPoints(alice, 80);

        assertEq(fxtlPoints.balanceOf(alice), 20);
        assertEq(fxtlPoints.totalSupply(), 20);
    }

    function test_BulkAddFxtlPoints() public {
        fxtlPoints.addFxtlContributor(bob);

        assertEq(fxtlPoints.balanceOf(alice), 0);
        assertEq(fxtlPoints.balanceOf(bob), 0);
        assertEq(fxtlPoints.totalSupply(), 0);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 100);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), bob, 200);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        hoax(bob);
        fxtlPoints.bulkAddFxtlPoints(recipients, amounts);

        assertEq(fxtlPoints.balanceOf(alice), 100);
        assertEq(fxtlPoints.balanceOf(bob), 200);
        assertEq(fxtlPoints.totalSupply(), 300);

        vm.expectRevert(FxtlPoints.NotFxtlContributor.selector);
        fxtlPoints.bulkAddFxtlPoints(recipients, amounts);

        uint256[] memory amounts2 = new uint256[](1);
        amounts2[0] = 100;
        vm.expectRevert(FxtlPoints.ArrayLengthMismatch.selector);
        hoax(bob);
        fxtlPoints.bulkAddFxtlPoints(recipients, amounts2);
    }

    function test_BulkRemoveFxtlPoints() public {
        fxtlPoints.addFxtlContributor(bob);

        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        hoax(bob);
        fxtlPoints.bulkAddFxtlPoints(recipients, amounts);

        assertEq(fxtlPoints.balanceOf(alice), 100);
        assertEq(fxtlPoints.balanceOf(bob), 200);
        assertEq(fxtlPoints.totalSupply(), 300);

        vm.expectRevert(FxtlPoints.NotFxtlContributor.selector);
        fxtlPoints.bulkRemoveFxtlPoints(recipients, amounts);

        uint256[] memory amounts2 = new uint256[](1);
        amounts2[0] = 100;
        vm.expectRevert(FxtlPoints.ArrayLengthMismatch.selector);
        hoax(bob);
        fxtlPoints.bulkRemoveFxtlPoints(recipients, amounts2);

        amounts[0] = 1000;
        vm.expectRevert(abi.encodeWithSelector(FxtlPoints.InsufficientFxtlPoints.selector, 100, 1000));
        hoax(bob);
        fxtlPoints.bulkRemoveFxtlPoints(recipients, amounts);

        amounts[0] = 100;
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, address(0), 100);
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, address(0), 200);
        hoax(bob);
        fxtlPoints.bulkRemoveFxtlPoints(recipients, amounts);

        assertEq(fxtlPoints.balanceOf(alice), 0);
        assertEq(fxtlPoints.balanceOf(bob), 0);
        assertEq(fxtlPoints.totalSupply(), 0);
    }

    function test_BulkFxtlPointsBalances() public {
        fxtlPoints.addFxtlContributor(bob);

        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        hoax(bob);
        fxtlPoints.bulkAddFxtlPoints(recipients, amounts);

        assertEq(fxtlPoints.balanceOf(alice), 100);
        assertEq(fxtlPoints.balanceOf(bob), 200);

        uint256[] memory balances = fxtlPoints.bulkFxtlPointsBalances(recipients);

        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
    }

    function test_Transfer() public {
        vm.expectRevert(FxtlPoints.TransferNotAllowed.selector);
        fxtlPoints.transfer(alice, 100);
    }

    function test_TransferFrom() public {
        vm.expectRevert(FxtlPoints.TransferNotAllowed.selector);
        fxtlPoints.transferFrom(alice, bob, 100);
    }
}
