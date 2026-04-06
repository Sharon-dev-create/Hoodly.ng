//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Types} from "./libraries/Types.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LeaseEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Immutable Variables
    IERC20 public immutable paymentToken;
    address public immutable landlord;
    address public immutable tenant;


    uint256 public immutable rentAmount;
    uint256 public immutable depositAmount;

    // Enum States
    enum State {
        Created,
        Funded,
        Active,
        Completed,
        Disputed,
        Resolved,
        Cancelled
    } 

    State public state;

    uint256 public startTime;
    uint256 public duration;

    //pull payments
    mapping(address => uint256) public pendingWithdrawals;
    mapping(address => uint256) public completedWithdrawals;

    // Events
    event Funded(address indexed tenant, uint256 amount);
    event Activated(uint256 startTime, uint256 duration);
    event RentReleased(uint256 amount);
    event DepositReturned(uint256 amount);
    event Disputed();
    event Resolved(address winner, uint256 amount);
    event Withdrawn(address indexed user, uint amount);

    // Constructor
    constructor(
        address _paymentToken,
        address _landlord,
        address _tenant,
        uint256 _rentAmount,
        uint256 _depositAmount,
        uint256 _duration
    ) {
        require(_paymentToken != address(0), "Invalid payment token");
        require(_landlord != address(0), "Invalid landlord address");
        require(_tenant != address(0), "Invalid tenant address");
        require(_rentAmount > 0, "Rent amount must be greater than zero");
        
        paymentToken = IERC20(_paymentToken);
        landlord = _landlord;
        tenant = _tenant;
        rentAmount = _rentAmount;
        depositAmount = _depositAmount;
        duration = _duration;

        state = State.Created;
    }
    

    // Core Functions
    function fund() external payable nonReentrant {
        require(msg.sender == tenant, "Only tenant");
        require(state == State.Created, "Already funded");

        uint256 totalAmount = rentAmount + depositAmount;

        uint256 beforeBal = paymentToken.balanceOf(address(this));
        paymentToken.safeTransferFrom(msg.sender, address(this), totalAmount);
        uint256 received = paymentToken.balanceOf(address(this)) - beforeBal;

        require(received == totalAmount, "Incorrect amount transferred");

        state = State.Funded;
        emit Funded(msg.sender, totalAmount); 
    }

    function activateLease() external {
        require(msg.sender == landlord, "Only landlord");
        require(state == State.Funded, "Lease not funded");

        state = State.Active;
        startTime = block.timestamp;

        emit Activated(startTime, duration);
    }

    
    function releaseRent() external {
        require(msg.sender == tenant, "Only tenant");
        require(state == State.Active, "Lease not active");

        state = State.Completed;

        pendingWithdrawals[landlord] += rentAmount;
        
        emit RentReleased(rentAmount);
    }

    function raiseDispute() private {
        require(msg.sender == tenant || msg.sender == landlord, "Only tenant or landlord");
        require(state == State.Active, "Lease not active");

        state = State.Disputed;

        emit Disputed();
    }

    function _raiseDispute() external {
        raiseDispute();
    }

    function cancelLease() external {
        require(msg.sender == tenant || msg.sender == landlord, "Only tenant or landlord");
        require(state == State.Created || state == State.Funded, "Cannot cancel active lease");

        State oldState = state;
        state = State.Cancelled;

        if(oldState == State.Funded) {
            pendingWithdrawals[tenant] += rentAmount + depositAmount;
        }
    }

    function returnDeposit() external {
        require(msg.sender == landlord, "Only landlord");
        require(state == State.Active, "Lease not active");

        state = State.Completed;

        pendingWithdrawals[tenant] += depositAmount;

        emit DepositReturned(depositAmount);
    }

    function resolveDispute(address winner, uint256 amount) external {
        require(state == State.Disputed, "No active dispute");
        require(winner == tenant || winner == landlord, "Invalid winner address");
        require(amount <= rentAmount + depositAmount, "Amount exceeds total escrow");

        state = State.Resolved;

        pendingWithdrawals[winner] += amount;

        emit Resolved(winner, amount);
    }

    // Withdraw Payments
    function withdraw(uint256 amount) external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingWithdrawals[msg.sender] = 0;
        
        paymentToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }
}
