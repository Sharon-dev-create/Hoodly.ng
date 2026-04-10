//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {LeaseEscrow} from "./leaseEscrow.sol";
import {ILeaseFactory} from "./interfaces/ILeaseFactory.sol";
import {IListingRegistry} from "./interfaces/IListingRegistry.sol";

contract LeaseFactory is ILeaseFactory {
    // Storage
    address public immutable paymentToken;
    address public immutable registry;
    address public treasury;
    uint256 public feeBps; // 200 = 2%

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
    constructor(address _paymentToken, address _registry, address _treasury, uint256 _feeBps) {
        require(_paymentToken != address(0), "Invalid payment token");
        require(_registry != address(0), "Invalid registry address");
        require(_treasury != address(0), "Invalid treasury address");
        require(_feeBps > 0, "Invalid fee basis points");

        paymentToken = _paymentToken;
        registry = _registry;
        treasury = _treasury;
        feeBps = _feeBps;
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
        require(leaseByListing[listingId] == address(0), "Lease already exists for listing");

        (address landlord, , , bool verified, uint8 status) = IListingRegistry(registry).getListing(listingId);
        require(msg.sender == landlord, "Only landlord");
        require(verified, "Listing is not verified");
        require(status == 0, "Listing is not active");

        // Create new LeaseEscrow contract
        lease = address(new LeaseEscrow(
            paymentToken,
            landlord,
            tenant,
            rent,
            deposit,
            365 days,
            feeBps,
            treasury
        ));

        // Store lease reference
        leaseByListing[listingId] = lease;
        allLeases.push(lease);

        // Emit event
        emit leaseCreated(lease, listingId, tenant, landlord);

        return lease;
    }

    function getLease(bytes32 listingId) external view returns (address) {
        return leaseByListing[listingId];
    }
}


