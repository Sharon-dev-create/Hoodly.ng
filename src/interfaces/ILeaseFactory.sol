// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILeaseFactory {
    event LeaseCreated(
        address indexed lease,
        bytes32 indexed listingId,
        address indexed tenant
    );

    function createLease(
        bytes32 listingId,
        address tenant,
        uint256 rent,
        uint256 deposit
    ) external returns (address lease);
}