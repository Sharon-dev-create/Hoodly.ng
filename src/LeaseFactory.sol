//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {LeaseEscrow} from "./leaseEscrow.sol";
import {ILeaseFactory} from "./interfaces/ILeaseFactory.sol";

contract LeaseFactory is ILeaseFactory {
    // Storage
    address public immutable paymentToken;
    address public immutable registry;

    //mappings
    mapping(bytes32 => address) public leaseByListing;

    // store all escrows for reference
    address[] public allLeases;

    // Events
    event leaseCreated(
        address indexed leaseEscrow,
        bytes32 indexed listingId,
        address indexed tenant,
        address landlord
    );

    // Constructor
    constructor(address _paymentToken, address _registry) {
        require(_paymentToken != address(0), "Invalid payment token");
        require(_registry != address(0), "Invalid registry address");

        paymentToken = _paymentToken;
        registry = _registry;
     }

    // Create LeaseFunction
    function createLease(
        bytes32 listingId,
        address tenant,
        uint256 rent,
        uint256 deposit
    ) external returns (address lease) {
        require(tenant != address(0), "invalid tenant");
        require(deposit > 0, "Insufficient deposit amount");
        require(rent > 0, "Rent amount must be greater than zero");

        // Create new LeaseEscrow contract
        // Note: landlord address needs to be fetched from registry based on listingId
        lease = address(new LeaseEscrow(
            paymentToken,
            address(0), // TODO: Get landlord from registry
            tenant,
            rent,
            deposit,
            365 days // TODO: Make duration configurable or fetch from listing
        ));

        // Store lease reference
        leaseByListing[listingId] = lease;
        allLeases.push(lease);

        // Emit event
        emit leaseCreated(lease, listingId, tenant, address(0)); // TODO: Update with actual landlord

        return lease;
    }
}


