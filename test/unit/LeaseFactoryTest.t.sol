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

    function setUp() public {
        // Deploy mock ERC20 token and listing registry
        leaseFactory = new LeaseFactory(address(publicToken), address(listingRegistry));
               
}
}