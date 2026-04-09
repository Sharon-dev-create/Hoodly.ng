// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {IListingRegistry} from "../interfaces/IListingRegistry.sol";
import {Types} from "../libraries/Types.sol";

contract MockListingRegistry is IListingRegistry {
    using Types for Types.Listing;

    mapping(bytes32 => Types.Listing) private listings;

    event ListingCreated(bytes32 indexed listingId, address indexed owner);
    event AgentAssigned(bytes32 indexed listingId, address indexed agent);

    function createListing(string calldata metadataURI) external returns (bytes32 listingId) {
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");

        listingId = keccak256(abi.encodePacked(msg.sender, metadataURI, block.number));
        require(listings[listingId].owner == address(0), "Listing already exists");

        listings[listingId] = Types.Listing({
            owner: msg.sender,
            agent: address(0),
            metadataURI: metadataURI,
            verified: false,
            status: Types.ListingStatus.Active
        });

        emit ListingCreated(listingId, msg.sender);
    }

    function verifyListing(bytes32 listingId) external {
        Types.Listing storage listing = listings[listingId];
        require(listing.owner != address(0), "Listing not found");
        require(!listing.verified, "Listing already verified");

        listing.verified = true;
        listing.agent = msg.sender;

        emit ListingVerified(listingId);
        emit AgentAssigned(listingId, msg.sender);
    }

    function pauseListing(bytes32 listingId) external {
        Types.Listing storage listing = listings[listingId];
        require(listing.owner != address(0), "Listing not found");

        listing.status = Types.ListingStatus.Paused;

        emit ListingPaused(listingId);
    }

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
        require(listing.owner != address(0), "Listing not found");

        return (
            listing.owner,
            listing.agent,
            listing.metadataURI,
            listing.verified,
            uint8(listing.status)
        );
    }
}
