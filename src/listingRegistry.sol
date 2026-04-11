//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IListingRegistry} from "./interfaces/IListingRegistry.sol";
import {Types} from "./libraries/Types.sol";


contract ListingRegistry is AccessControl, IListingRegistry {
    using Types for Types.Listing;

    // State Variables
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    mapping(bytes32 => Types.Listing) private listings;

    // Events
    event ListingCreated(bytes32 indexed listingId, address indexed owner);
    event AgentAssigned(bytes32 indexed listingId, address indexed agent);
  
    constructor(address admin) {
        require(admin != address(0), "Admin address cannot be zero");   
        require(admin != msg.sender, "Admin cannot be the deployer");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _setRoleAdmin(AGENT_ROLE, ADMIN_ROLE);
        
    }

    // Create Listing
    function createListing(string calldata metadataURI) external returns(bytes32 listingId){
       require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty"); 
       
       listingId = keccak256(abi.encodePacked(msg.sender, metadataURI, block.number));
       require(listings[listingId].owner == address(0), "Listing already exists");

       // Store the listing
       listings[listingId] = Types.Listing({
        owner: msg.sender,
        agent: address(0),
        metadataURI: metadataURI,
        verified: false,
        status: Types.ListingStatus.Active
       });
 
       // Emit event
       emit ListingCreated(listingId, msg.sender);
    }

    function verifyListing(bytes32 listingId) external {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(AGENT_ROLE, msg.sender), "Not Authorized");
        require(listings[listingId].owner != address(0), "Listing not found");
        require(!listings[listingId].verified, "Listing already verified");

        // Update listing status
        listings[listingId].verified = true;
        listings[listingId].agent = msg.sender;

        // Emit event
        emit ListingVerified(listingId);
        emit AgentAssigned(listingId, msg.sender);
    }

    function pauseListing(bytes32 listingId) external onlyRole(ADMIN_ROLE) {
        Types.Listing storage listing = listings[listingId];
        require(listing.owner != address(0), "Listing not found");  

        listing.status = Types.ListingStatus.Paused;
        
        emit ListingPaused(listingId);        
       
    }

    function assignAgent(bytes32 listingId, address agent) external onlyRole(ADMIN_ROLE) {
        require(agent != address(0), "Agent address cannot be zero");
        Types.Listing storage listing = listings[listingId];
        require(listing.owner != address(0), "Listing not found");

        listing.agent = agent;

        emit AgentAssigned(listingId, agent);
    }

// Read Functions
    function getListing(bytes32 listingId)
        external
        view
        returns (
            address owner,
            address agent,
            string memory metadataURI,
            bool verified,
            uint8 status
        )
    {
        Types.Listing storage listing = listings[listingId];
        require(listings[listingId].owner != address(0), "Listing not found");

        return (
            listing.owner,
            listing.agent,
            listing.metadataURI,
            listing.verified,
            uint8(listing.status)
        );
    }
}
