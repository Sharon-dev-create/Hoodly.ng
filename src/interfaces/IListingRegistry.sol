
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

interface IListingRegistry {
    // event ListingCreated(bytes32 indexed listingId, address indexed owner);
    event ListingVerified(bytes32 indexed listingId);
    event ListingPaused(bytes32 indexed listingId);

    function createListing(string calldata metadataURI) external returns (bytes32);

    function verifyListing(bytes32 listingId) external;

    function pauseListing(bytes32 listingId) external;

    function getListing(bytes32 listingId)
        external
        view
        returns (
            address owner,
            address agent,
            string memory metadataURI,
            bool verified,
            uint8 status
        );
}
