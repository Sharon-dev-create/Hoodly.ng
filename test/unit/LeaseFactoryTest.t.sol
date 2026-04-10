//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LeaseFactory} from "../../src/LeaseFactory.sol";
import {LeaseEscrow} from "../../src/leaseEscrow.sol";
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
    address public treasury = address(0xABC);
    uint256 public rentAmount = 1000e18; // 1000 tokens with 18 decimals
    uint256 public securityDeposit = 2000e18; // 2000 tokens with 18 decimals
    uint256 public feeBps = 200; // 2%

    event leaseCreated(address indexed leaseEscrow, bytes32 indexed listingId, address indexed tenant, address landlord);
    uint256 public leaseDuration = 30 days;

    bytes32 listingId = keccak256(abi.encodePacked(landlord, "https://example.com/listing/1", block.number));

    function setUp() public {
        // Deploy mock ERC20 token and listing registry
        publicToken = new MockERC20();
        listingRegistry = new MockListingRegistry();
        leaseFactory = new LeaseFactory(address(publicToken), address(listingRegistry), treasury, feeBps);
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

    function testRevertIfRentIsZero() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Attempt to create lease with zero rent should revert
        vm.prank(landlord);
        vm.expectRevert("Rent amount must be greater than zero");
        leaseFactory.createLease(listingId, tenant, 0, securityDeposit);
    }

    function testLeaseStored() public {
         // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        vm.prank(landlord);
        address lease = leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);

        address storedLease = leaseFactory.leaseByListing(listingId);

        assertEq(storedLease, lease);
    }

    function testMultipleLeasesForSameListing() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Create first lease
        vm.prank(landlord);
        leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);

        // Attempt to create second lease for same listing should revert
        vm.prank(landlord);
        vm.expectRevert("Lease already exists for listing");
        leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);
}
    
    function testTotalLeases() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Create lease
        vm.prank(landlord);
        address lease = leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);

        // Check total leases
        assertEq(leaseFactory.allLeases(0), lease);
    }

    function testEventEmits() public {
         // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        vm.prank(landlord);
        vm.expectEmit(false, true, true, true);

        emit leaseCreated(address(0), listingId, tenant, landlord);

        leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);

    }

    function testCreateLeaseOnNonExistentListing() public {
        bytes32 fakeListingId = keccak256("fake");
        vm.prank(landlord);
        vm.expectRevert("Listing not found");
        leaseFactory.createLease(fakeListingId, tenant, rentAmount, securityDeposit);
    }

    function testCreateLeaseOnPausedListing() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Pause the listing
        vm.prank(landlord);
        listingRegistry.pauseListing(listingId);

        // Attempt to create lease should revert
        vm.prank(landlord);
        vm.expectRevert("Listing is not active");
        leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);
    }

    function testMultipleListingsMultipleLeases() public {
        // Create first listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Create second listing
        bytes32 listingId2 = keccak256(abi.encodePacked(landlord, "https://example.com/listing/2", block.number));
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/2");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId2);

        // Create leases
        vm.prank(landlord);
        address lease1 = leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);
        vm.prank(landlord);
        address lease2 = leaseFactory.createLease(listingId2, tenant, rentAmount, securityDeposit);

        // Check mappings
        assertEq(leaseFactory.leaseByListing(listingId), lease1);
        assertEq(leaseFactory.leaseByListing(listingId2), lease2);

        // Check allLeases array
        assertEq(leaseFactory.allLeases(0), lease1);
        assertEq(leaseFactory.allLeases(1), lease2);
    }

    function testLeaseEscrowParameters() public {
        // Create and verify listing
        vm.prank(landlord);
        listingRegistry.createListing("https://example.com/listing/1");
        vm.prank(landlord);
        listingRegistry.verifyListing(listingId);

        // Create lease
        vm.prank(landlord);
        address leaseAddr = leaseFactory.createLease(listingId, tenant, rentAmount, securityDeposit);

        // Check the escrow parameters
        LeaseEscrow escrow = LeaseEscrow(leaseAddr);
        assertEq(address(escrow.paymentToken()), address(publicToken));
        assertEq(escrow.landlord(), landlord);
        assertEq(escrow.tenant(), tenant);
        assertEq(escrow.rentAmount(), rentAmount);
        assertEq(escrow.depositAmount(), securityDeposit);
    }
}