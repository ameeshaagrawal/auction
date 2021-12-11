// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AuctionStorage is Ownable {
    enum States {
        BETTING,
        WORK_IN_PROGRESS,
        TASK_SUBMITTED,
        CANCELLED,
        SLASHED,
        INVALID
    }

    struct Task {
        address taskOwner;
        bytes32 taskDescription;
        uint256 taskStartTime;
        uint256 taskTimeLimit;
        address workerSelected;
        uint256 bidAmount;
        uint256 amountStaked;
        bytes32 submittedWork;
        bool isSettled;
    }

    mapping(uint256 => Task) public tasks;

    uint256 public bettingPeriod;
    uint256 public taskSettlementPeriod;
    uint256 public taskId;
    uint256 public MIN_BET_STAKE = 10**8;

    event BettingPeriodUpdated(uint256 bettingPeriod);
    event TaskSettlementPeriodUpdated(uint256 taskSettlementPeriod);
    event BetStakeUpdated(uint256 betStake);
    event TaskCreated(
        address taskOwner,
        uint256 taskId,
        bytes32 taskDescription,
        uint256 timeLimit,
        uint256 creationTimestamp
    );
    event BetPlaced(address indexed bidder, uint256 betAmount, uint256 taskId);
    event TaskSettled(
        uint256 taskId,
        address indexed paidTo,
        uint256 amountPaid
    );
}
