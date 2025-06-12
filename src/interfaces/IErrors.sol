//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface PollCreationErrors {
    error InsufficientNumberOfOptions();
    error EndTimeMustBeAFutureTime();
    error NotAValidERC20ContractAddress();
    error InsufficientFee(uint256 minFee, uint256 paidFee);
}

interface VotingErrors {
    error InvalidPollId();
    error InvalidOptionIndex();
    error VotingNotStarted();
    error VotingHasEnded();
    error NotEnoughTokenBalance();
    error AlreadyVoted();
}
