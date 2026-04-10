//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {LeaseEscrow} from "../../src/leaseEscrow.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";


contract LeaseEscrowTest is Test {
    LeaseEscrow escrow;
    ERC20Mock paymentToken;

    address landlord = address(0x123);
    address tenant = address(0x456);
    address randomUser = address(0xabc);
    address arbitrator = address(4);
    address treasury = address(0xdef);

    uint256 rentAmount = 1000e18;
    uint256 depositAmount = 2000e18;
    uint256 duration = 30 days;
    uint256 feeBps = 200;

    function setUp() public{
      paymentToken = new ERC20Mock();
      escrow = new LeaseEscrow(
        address(paymentToken),
        landlord,
        tenant, 
        rentAmount,
        depositAmount,
        duration,
        feeBps,
        treasury
      );
    }

    function testInitialState() public {
        assertEq(address(escrow.paymentToken()), address(paymentToken));
        assertEq(escrow.landlord(), landlord);
        assertEq(escrow.tenant(), tenant);
        assertEq(escrow.rentAmount(), rentAmount);
        assertEq(escrow.depositAmount(), depositAmount);
        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Created));
    }


    function testFund() public {
        uint256 totalAmount = rentAmount + depositAmount;

        paymentToken.mint(tenant, totalAmount);
        vm.prank(tenant);
        paymentToken.approve(address(escrow), totalAmount);

        vm.prank(tenant);
        escrow.fund();

        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Funded));
        assertEq(paymentToken.balanceOf(address(escrow)), totalAmount);
    }

    function testInsufficientFunds() public {
        uint256 totalAmount = rentAmount + depositAmount;

        paymentToken.mint(tenant, rentAmount); // Only mint rent, not deposit
        vm.prank(tenant);
        paymentToken.approve(address(escrow), totalAmount);

        vm.prank(tenant);
        vm.expectRevert();
        escrow.fund();
    }
    
    function testRevertIfNotTenant() public {
      vm.prank(randomUser);

      vm.expectRevert("Only tenant");
      escrow.fund();
    }

    function testLeaseActivation() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.activateLease();

        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Active));
    }

    function testRevertActivateIfNotLandlord() public {
        vm.prank(randomUser);
        vm.expectRevert("Only landlord");
        escrow.activateLease();
    }

    function testReleaseRent() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.activateLease();

        vm.prank(tenant);
        escrow.releaseRent();
        uint256 landlordAmount = rentAmount - ((rentAmount * feeBps) / 10000);
        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Completed));
        assertEq(escrow.pendingWithdrawals(landlord), landlordAmount);
    }

    function testLandlordCanReleaseRentAfterGracePeriod() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.activateLease();

        vm.warp(block.timestamp + 21 days);
        vm.prank(landlord);
        escrow.releaseRent();

        uint256 landlordAmount = rentAmount - ((rentAmount * feeBps) / 10000);
        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Completed));
        assertEq(escrow.pendingWithdrawals(landlord), landlordAmount);
    }

    function testDisputeCanBeRaised() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.activateLease();

        vm.prank(tenant);
        escrow._raiseDispute();
        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Disputed));
    }

    function testRevertDisputeIfNotTenantOrLandlord() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.activateLease();

        vm.prank(randomUser);
        vm.expectRevert("Only tenant or landlord");
        escrow._raiseDispute();
    }

    function testReturnDeposit() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.activateLease();

        vm.prank(landlord);
        escrow.returnDeposit();

        vm.prank(tenant);
        escrow.withdraw(depositAmount);

        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Completed));
        assertEq(paymentToken.balanceOf(tenant), depositAmount);
    }

    function testCancelLease() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.cancelLease();

        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Cancelled));
        assertEq(escrow.pendingWithdrawals(tenant), totalAmount);
    }

    function testWithdraw() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        vm.prank(landlord);
        escrow.activateLease();

        vm.prank(tenant);
        escrow.releaseRent();

        uint256 landlordAmount = rentAmount - ((rentAmount * feeBps) / 10000);
        vm.prank(landlord);
        escrow.withdraw(landlordAmount);

        assertEq(paymentToken.balanceOf(landlord), landlordAmount);
    }

    function testDisputeFlow() public {
        uint256 totalAmount = rentAmount + depositAmount;

        vm.startPrank(tenant);
        paymentToken.mint(tenant, totalAmount);
        paymentToken.approve(address(escrow), totalAmount);
        escrow.fund();
        vm.stopPrank();

        // landlord activates Lease
        vm.prank(landlord);
        escrow.activateLease();

        // Raise dispute
        vm.prank(tenant);
        escrow._raiseDispute();

        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Disputed));

        //Resolve dispute
        vm.prank(arbitrator);
        escrow.resolveDispute(tenant, totalAmount);

        assertEq(uint(escrow.state()), uint(LeaseEscrow.State.Resolved));
        assertEq(escrow.pendingWithdrawals(tenant), totalAmount);
    }

    function testRevertIfNothingToWithdraw(uint256 amount) public {
      // uint256 totalAmount = rentAmount + depositAmount;
        vm.prank(landlord);

        vm.expectRevert("Nothing to withdraw");
        escrow.withdraw(amount);
    }

}