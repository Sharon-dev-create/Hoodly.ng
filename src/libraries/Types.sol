// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library Types {
    enum ListingStatus {
        Active,
        Paused
    }

    enum LeaseState {
        Created,
        Funded,
        Active,
        Completed,
        Disputed,
        Cancelled
    }

    struct Listing {
        address owner;
        address agent;
        string metadataURI;
        bool verified;
        ListingStatus status;
    }

    struct LeaseData {
        address landlord;
        address tenant;
        uint256 rent;
        uint256 deposit;
        LeaseState state;
    }
}