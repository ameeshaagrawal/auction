// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./AuctionStorage.sol";

contract Auction is AuctionStorage {
    using SafeMath for uint256;

    constructor(uint256 _bettingPeriod, uint256 _taskSettlementPeriod) {
        require(_bettingPeriod != 0, "INVALID_BETTING_PERIOD");
        require(_taskSettlementPeriod != 0, "INVALID_BETTING_PERIOD");

        bettingPeriod = _bettingPeriod;
        taskSettlementPeriod = _taskSettlementPeriod;
    }

    function updateBettingPeriod(uint256 _bettingPeriod) external onlyOwner {
        require(_bettingPeriod != 0, "INVALID_BETTING_PERIOD");
        bettingPeriod = _bettingPeriod;

        emit BettingPeriodUpdated(_bettingPeriod);
    }

    function updateTaskSettlementPeriod(uint256 _taskSettlementPeriod)
        external
        onlyOwner
    {
        require(_taskSettlementPeriod != 0, "INVALID_SETTLEMENT_PERIOD");
        taskSettlementPeriod = _taskSettlementPeriod;
        emit TaskSettlementPeriodUpdated(_taskSettlementPeriod);
    }

    function updateMinBetStake(uint256 _minBetStake) external onlyOwner {
        require(_minBetStake != 0, "INVALID_MIN_BET_STAKE");
        MIN_BET_STAKE = _minBetStake;
        emit BetStakeUpdated(_minBetStake);
    }

    function createTask(bytes32 taskDescription, uint256 timeLimit) external {
        require(taskDescription != bytes32(0), "NEED_TASK_DESCRIPTION");
        require(timeLimit != 0, "TIME_LIMIT_CANNOT_BE_ZERO");

        taskId = taskId + 1;

        Task storage _task = tasks[taskId];
        _task.taskDescription = taskDescription;
        _task.taskTimeLimit = timeLimit;
        _task.taskStartTime = block.timestamp;
        _task.taskOwner = msg.sender;

        emit TaskCreated(
            msg.sender,
            taskId,
            taskDescription,
            timeLimit,
            block.timestamp
        );
    }

    function bet(uint256 taskId, uint256 bidAmount) external payable {
        Task storage task = tasks[taskId];
        require(getState(taskId) == States.BETTING, "NOT_IN_BETTING_STATE");
        require(msg.value >= MIN_BET_STAKE, "NEED_MIN_STAKE");
        require(bidAmount != 0, "BET_AMOUNT_CANNOT_BE_ZERO");
        address previousWorker;
        uint256 previousBet;
        if (task.bidAmount > 0) {
            require(bidAmount < task.bidAmount, "BET_AMOUNT_HIGH");
            previousWorker = task.workerSelected;
            previousBet = task.amountStaked;
        }

        task.amountStaked = msg.value;
        task.bidAmount = bidAmount;
        task.workerSelected = msg.sender;

        if (previousBet > 0) safeTransferETH(previousWorker, previousBet);

        emit BetPlaced(msg.sender, msg.value, taskId);
    }

    function submitTask(uint256 taskId, bytes32 work) external {
        require(
            getState(taskId) == States.WORK_IN_PROGRESS,
            "WORK_CANNOT_BE_SUBMITTED"
        );
        Task storage task = tasks[taskId];
        task.submittedWork = work;
    }

    function settleWork(uint256 taskId) external payable {
        States state = getState(taskId);
        Task storage task = tasks[taskId];

        require(
            state == States.TASK_SUBMITTED || state == States.SLASHED,
            "CANNOT_BE_SETTLED"
        );
        require(!task.isSettled, "ALREADY_SETTLED");

        address paidTo;
        uint256 amountPaid = task.amountStaked.add(msg.value);

        if (state == States.TASK_SUBMITTED) {
            require(msg.value >= task.bidAmount, "NO_PAYMENT_RECEIVED");
            paidTo = task.workerSelected;
        } else if (state == States.SLASHED) {
            paidTo = task.taskOwner;
        }

        task.isSettled = true;

        safeTransferETH(paidTo, amountPaid);
        emit TaskSettled(taskId, paidTo, amountPaid);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    function getState(uint256 taskId) public view returns (States) {
        Task memory task = tasks[taskId];

        if (task.taskOwner == address(0)) {
            return States.INVALID;
        }

        if (block.timestamp <= bettingPeriod.add(task.taskStartTime)) {
            return States.BETTING;
        }

        if (task.bidAmount == 0) {
            return States.CANCELLED;
        }

        if (task.submittedWork != bytes32(0)) {
            return States.TASK_SUBMITTED;
        }

        if (
            block.timestamp >
            (task.taskStartTime).add(bettingPeriod).add(task.taskTimeLimit).add(
                taskSettlementPeriod
            )
        ) {
            return States.SLASHED;
        }

        return States.WORK_IN_PROGRESS;
    }
}
