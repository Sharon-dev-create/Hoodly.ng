// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 public token;

    address public alice = address(0x123);
    address public bob = address(0x456);
    uint256 public initialSupply = 1000e18;

    function setUp() public {
        token = new MockERC20();
    }

    function testConstructor() public {
        assertEq(token.name(), "MockERC20");
        assertEq(token.symbol(), "MERC");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }

    function testMint() public {
        token.mint(alice, initialSupply);
        assertEq(token.balanceOf(alice), initialSupply);
        assertEq(token.totalSupply(), initialSupply);
    }

    function testBurn() public {
        token.mint(alice, initialSupply);
        token.burn(alice, 500e18);
        assertEq(token.balanceOf(alice), 500e18);
        assertEq(token.totalSupply(), 500e18);
    }

    function testBurnInsufficientBalance() public {
        token.mint(alice, 100e18);
        vm.expectRevert();
        token.burn(alice, 200e18);
    }

    function testTransfer() public {
        token.mint(alice, initialSupply);
        vm.prank(alice);
        token.transfer(bob, 500e18);
        assertEq(token.balanceOf(alice), 500e18);
        assertEq(token.balanceOf(bob), 500e18);
    }

    function testApproveAndTransferFrom() public {
        token.mint(alice, initialSupply);
        vm.prank(alice);
        token.approve(bob, 500e18);
        assertEq(token.allowance(alice, bob), 500e18);

        vm.prank(bob);
        token.transferFrom(alice, bob, 500e18);
        assertEq(token.balanceOf(alice), 500e18);
        assertEq(token.balanceOf(bob), 500e18);
        assertEq(token.allowance(alice, bob), 0);
    }
}