//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LeaseFactory} from "../../src/LeaseFactory.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {MockListingRegistry} from "../../src/mocks/MockListingRegistry.sol";

contract LeaseFactoryTest is Test {
    // State variables
    LeaseFactory public leaseFactory;
    MockERC20 public publicToken;
    MockListingRegistry public listingRegistry;

    address public landlord = address(0x123);
    address public tenant = address(0x456);
    address public attacker = address(0x789);
    uint256 public rentAmount = 1000e18; // 1000 tokens with 18 decimals
    uint256 public securityDeposit = 2000e18; // 2000 tokens with 18 decimals
    uint256 public leaseDuration = 30 days;

    bytes32 listingId = keccak256(abi.encodePacked(landlord, "https://example.com/listing/1", block.number));

    function setUp() public {
        // Deploy mock ERC20 token and listing registry
        publicToken = new MockERC20();
        listingRegistry = new MockListingRegistry();
        leaseFactory = new LeaseFactory(address(publicToken), address(listingRegistry));
    }

    function testCreateLease() public {
        // Create a listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");

        // Verify the listing
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Create lease
        vm.prank(landlord);
        leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);

        // Assertions
        address leaseAddress = leaseFactory.leaseByListing(listingId);
        assertTrue(leaseAddress != address(0), "Lease should be created");
    }

    function testRevertIfListingIsNotVerified() public {
        // Create a listing without verifying
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");

        // Attempt to create lease should revert
        vm.prank(landlord);

        vm.expectRevert("Listing is not verified");
        leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);
    }

    function testRevertIfNotLandlord() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Attempt to create lease by non-landlord should revert
        vm.prank(attacker);
        vm.expectRevert("Only landlord");
        leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);
    }

    function testRevertIfTenantDoesNotExist() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Attempt to create lease with zero address tenant should revert
        vm.prank(landlord);
        vm.expectRevert("invalid tenant");
        leaseFactory.createLease(listingId, address(0), rentAmount, securityDeposit);
    }

    function testRevertIfDepositIsZero() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Attempt to create lease with zero deposit should revert
        vm.prank(landlord);
        vm.expectRevert("Insufficient deposit amount");
        leaseFactory.createLease(listingId, tenant, rentAmount, 0);
    }
    }
