//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IPoll} from "src/interfaces/IPoll.sol";
import {VotingErrors} from "src/interfaces/IErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title VotingV1
/// @author Sudip Roy
/// @notice This contract holds the logic that allows users to vote on polls created by the PollCreation contract using ERC20 token eligibility.
/// @dev Ensures each user can only vote once per poll and tracks votes per option.
contract VotingV1 is Initializable {
    address private s_pollCreationFactory;
    mapping(address user => mapping(uint256 pollId => uint256 optionIndex)) private s_userVote;
    mapping(uint256 pollId => mapping(uint256 optionIndex => uint256 numVotes)) private s_votesPerOption;
    mapping(address user => mapping(uint256 pollId => bool)) private s_hasUserVoted;

    /// @notice Emitted when a vote is cast.
    /// @param pollId The ID of the poll voted on.
    /// @param optionVoted The index of the option that was voted for.
    /// @param voter The address of the user who cast the vote.
    event VoteCasted(uint256 indexed pollId, uint256 indexed optionVoted, address indexed voter);

    /// @notice Initializes the VotingV1 contract with the PollCreation factory address.
    /// @dev uses initializer modifier to restrict it from getting initialized more than once
    /// @dev uses openzeppelin transparent proxy standard
    /// @param pollCreationFactory The address of the PollCreation contract.
    function initialize(address pollCreationFactory) external initializer {
        s_pollCreationFactory = pollCreationFactory;
    }

    /// @notice Cast a vote on a poll.
    /// @dev Ensures the poll exists, voting period is active, and user has not already voted.
    /// @param pollId The ID of the poll to vote in.
    /// @param optionIndex The index of the chosen option.
    function vote(uint256 pollId, uint256 optionIndex) external {
        require(!s_hasUserVoted[msg.sender][pollId], VotingErrors.AlreadyVoted());
        require(pollId != 0, VotingErrors.InvalidPollId());
        IPoll.Poll memory poll = IPoll(s_pollCreationFactory).getPollById(pollId);
        require(optionIndex < poll.options.length, VotingErrors.InvalidOptionIndex());
        require(block.timestamp >= poll.startTime, VotingErrors.VotingNotStarted());
        require(block.timestamp <= poll.endTime, VotingErrors.VotingHasEnded());
        require(IERC20(poll.erc20).balanceOf(msg.sender) >= 1, VotingErrors.NotEnoughTokenBalance());
        s_hasUserVoted[msg.sender][pollId] = true;
        s_userVote[msg.sender][pollId] = optionIndex + 1;
        s_votesPerOption[pollId][optionIndex + 1] += 1;
        emit VoteCasted(pollId, optionIndex, msg.sender);
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

    /// @notice Returns the address of the PollCreation factory.
    /// @return The address of the PollCreation factory contract.
    function getPollCreationFactoryAddress() external view returns (address) {
        return s_pollCreationFactory;
    }
}
