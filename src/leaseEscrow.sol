//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

contract leaseEscrow {
    // Variables
    address public tenant;

    uint256 public rent;
    uint256 public deposit;

    enum State {
        Created,
        Funded,
        Active,
        Completed,
        Disputed,
        Cancelled
    }

    // Core Functions
    function fund() external payable returns(uint256) {

    }

    function confirmMoveIn() private pure {

    }

    function releaseRent() public pure {

    }

    function endLease() public {

    }

    function raiseDispute() private returns(bool){
        
    }
}