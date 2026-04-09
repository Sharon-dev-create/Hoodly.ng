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

    bytes32 listingId = keccak256(abi.encodePacked(landlord, "https://example.com/listing/1", block.number));

    function setUp() public {
        // Deploy mock ERC20 token and listing registry
        leaseFactory = new LeaseFactory(address(publicToken), address(listingRegistry));
        publicToken = new MockERC20();
        listingRegistry = new MockListingRegistry();

    }
}
