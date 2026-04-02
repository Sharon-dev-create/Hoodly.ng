//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ListingRegistry} from "../../src/listingRegistry.sol";
import {Test} from "forge-std/Test.sol";
import {Types} from "../../src/libraries/Types.sol";

contract ListingRegistryTest is Test {
   ListingRegistry registry;

   address landlord = address(0x123);
   address tenant = address(0x456);
   address agent = address(0x789);
   address randomUser = address(0xabc);
   address admin = address(0x999);

   function setUp() public {
       registry = new ListingRegistry(admin);
   }

   function testCreateListing() public {
        vm.prank(landlord);

        bytes32 listingId = registry.createListing("https://example.com/image.jpg");
        (address owner,
        address listingAgent,
        string memory uri,
        bool verified,
        uint8 status) = registry.getListing(listingId);

        assertEq(owner, landlord);
        assertEq(uri, "https://example.com/image.jpg");
        assertEq(verified, false);
        assertEq(status, uint8(Types.ListingStatus.Active));
        assertEq(listingAgent, address(0));
   }

   function testRevertEmptyMetadata() public {
        vm.prank(landlord);
        vm.expectRevert("Metadata URI cannot be empty");
        registry.createListing("");
   }        

   function testRevertDuplicateListing() public {
    vm.prank(landlord);

    registry.createListing("https://example.com/image.jpg");
    vm.prank(landlord);
    vm.expectRevert("Listing already exists");
    registry.createListing("https://example.com/image.jpg");
   }

   function testVerifyListing() public {
        vm.prank(landlord);
        bytes32 listingId = registry.createListing("https://example.com/image.jpg");

        vm.prank(agent);
        vm.expectRevert();
        registry.verifyListing(listingId);

        vm.prank(admin);
        registry.verifyListing(listingId);

        (,
        address listingAgent,
        ,
        bool verified,
        ) = registry.getListing(listingId);

        assertEq(verified, true);
        assertEq(listingAgent, admin);
   }

   function testRevertUnauthorizedVerification() public {
        vm.prank(landlord);
        bytes32 listingId = registry.createListing("https://example.com/image.jpg");

        vm.prank(randomUser);
        vm.expectRevert("Not Authorized");
        registry.verifyListing(listingId);
   }

   function testPauseListing() public {
        vm.prank(landlord);
        bytes32 listingId = registry.createListing("https://example.com/image.jpg");
 
        vm.prank(admin);
        registry.pauseListing(listingId);

        (, , , , uint8 status) = registry.getListing(listingId);
        assertEq(status, uint8(Types.ListingStatus.Paused));
   }

   function testAgentAssignment() public {
        vm.prank(landlord);
        bytes32 listingId = registry.createListing("https://example.com/image.jpg");

        vm.prank(admin);
        registry.assignAgent(listingId, agent);

        (, address listingAgent, , ,) = registry.getListing(listingId);
        assertEq(listingAgent, agent);
   }
}