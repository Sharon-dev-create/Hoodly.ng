//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IListingRegistry} from "./interfaces/IListingRegistry.sol";


contract ListingRegistry is AccessControl, IListingRegistry {
    // State variables


    //// Structs
    struct Listing {
        address owner;
        address agent;
        string metadataURI;
        bool verified;
        bool active;
    }
  
    constructor() {
        
    }

    // Create Listing
    function createListing(string calldata metadataURI) external returns(bytes32){

    }

    function veryfifyListing(bytes32 listingId) external view returns(bool){

    }

    function pauseListing(bytes32 listingId) external {

    }

    function getListing(bytes32 listingId) external view returns(string memory){

    }

    function getListing(bytes listingId) external view returns(string memory){

    }   

}