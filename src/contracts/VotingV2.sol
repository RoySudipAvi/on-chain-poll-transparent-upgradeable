//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPoll} from "src/interfaces/IPoll.sol";
import {VotingErrors} from "src/interfaces/IErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title VotingV2
/// @author Sudip Roy
/// @notice This contract holds the logic that allows users to vote on polls created by the PollCreation contract using ERC20 token eligibility.
/// @dev Ensures each user can only vote once per poll and tracks votes per option.
/// @dev Votes will be weighted, meaning instead of one votes per Option, votes will counted as number of specified erc20 Tokens held by the voter.
contract VotingV2 {
    address private s_pollCreationFactory;
    mapping(address user => mapping(uint256 pollId => uint256 optionIndex)) private s_userVote;
    mapping(uint256 pollId => mapping(uint256 optionIndex => uint256 numVotes)) private s_votesPerOption;
    mapping(address user => mapping(uint256 pollId => bool)) private s_hasUserVoted;
    mapping(address user => mapping(uint256 pollId => mapping(uint256 optionIndex => uint256 numOfVotes))) private
        s_userVoteNumVotes;

    /// @notice Emitted when a vote is cast.
    /// @param pollId The ID of the poll voted on.
    /// @param optionVoted The index of the option that was voted for.
    /// @param voter The address of the user who cast the vote.
    event VoteCastedV2(uint256 indexed pollId, uint256 indexed optionVoted, address indexed voter, uint256 numVotes);

    /// @notice Cast vote on a poll.
    /// @dev Ensures the poll exists, voting period is active, and user has not already voted.
    /// @dev Votes will be added equivalent of specified erc20 tokens held by the voter
    /// @param pollId The ID of the poll to vote in.
    /// @param optionIndex The index of the chosen option.
    function vote(uint256 pollId, uint256 optionIndex) external {
        require(!s_hasUserVoted[msg.sender][pollId], VotingErrors.AlreadyVoted());
        require(pollId != 0, VotingErrors.InvalidPollId());
        IPoll.Poll memory poll = IPoll(s_pollCreationFactory).getPollById(pollId);
        require(optionIndex < poll.options.length, VotingErrors.InvalidOptionIndex());
        require(block.timestamp >= poll.startTime, VotingErrors.VotingNotStarted());
        require(block.timestamp <= poll.endTime, VotingErrors.VotingHasEnded());
        uint256 voterBalance = IERC20(poll.erc20).balanceOf(msg.sender);
        require(voterBalance >= 1e18, VotingErrors.NotEnoughTokenBalance());
        s_hasUserVoted[msg.sender][pollId] = true;
        s_userVote[msg.sender][pollId] = optionIndex + 1;
        s_userVoteNumVotes[msg.sender][pollId][optionIndex + 1] = voterBalance / 1e18;
        s_votesPerOption[pollId][optionIndex + 1] += voterBalance / 1e18;
        emit VoteCastedV2(pollId, optionIndex, msg.sender, voterBalance / 1e18);
    }

    /// @notice Returns whether a user has voted in a specific poll.
    /// @param user The address of the user to check.
    /// @param pollId The ID of the poll.
    /// @return True if the user has already voted, false otherwise.
    function hasUserVoted(address user, uint256 pollId) external view returns (bool) {
        return s_hasUserVoted[user][pollId];
    }

    /// @notice Returns the number of votes received by a specific option in a poll.
    /// @param pollId The ID of the poll.
    /// @param optionId The index of the option.
    /// @return The number of votes for the specified option.
    function votesPerOption(uint256 pollId, uint256 optionId) external view returns (uint256) {
        return s_votesPerOption[pollId][optionId + 1];
    }

    /// @notice Returns the option index voted for by a specific user in a poll.
    /// @param user The address of the user.
    /// @param pollId The ID of the poll.
    /// @return The option index (zero-based) voted for by the user.
    function userVote(address user, uint256 pollId) external view returns (uint256) {
        return s_userVote[user][pollId] - 1;
    }

    /// @notice Returns the number of votes for the option index voted for by a specific user in a poll.
    /// @param user The address of the user.
    /// @param pollId The ID of the poll.
    /// @param optionId The Option index.
    /// @return The number of votes casted for this by the user.
    function userVoteNumVotes(address user, uint256 pollId, uint256 optionId) external view returns (uint256) {
        return s_userVoteNumVotes[user][pollId][optionId + 1];
    }

    /// @notice Returns the address of the PollCreation factory.
    /// @return The address of the PollCreation factory contract.
    function getPollCreationFactoryAddress() external view returns (address) {
        return s_pollCreationFactory;
    }
}
