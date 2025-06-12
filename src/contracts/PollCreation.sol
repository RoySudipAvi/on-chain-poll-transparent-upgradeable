//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PollCreationErrors} from "src/interfaces/IErrors.sol";
import {IPoll} from "src/interfaces/IPoll.sol";

/// @title PollCreation
/// @author Sudip Roy
/// @notice This contract enables users to create polls with multiple options.
/// @dev Stores polls and allows querying all polls and poll details.
contract PollCreation is IPoll {
    address public immutable I_ADMIN;
    mapping(uint256 pollId => Poll) private s_idToPoll;
    Poll[] private s_polls;
    uint256 private s_minimumFeeInETH;

    /// @notice Emitted when a new poll is created.
    /// @param owner The address of the poll creator.
    /// @param erc20 The address of the ERC20 token for voting eligibility.
    /// @param question The poll question.
    event PollCreated(address indexed owner, address indexed erc20, string question);

    constructor(uint256 minFee) {
        I_ADMIN = msg.sender;
        s_minimumFeeInETH = minFee;
    }

    /// @notice Create a new poll.
    /// @dev Requires a minimum ETH fee and valid input data.
    /// @param question The poll question.
    /// @param options The options available in the poll (minimum 2).
    /// @param startTime The start time for voting (UNIX timestamp).
    /// @param endTime The end time for voting (UNIX timestamp).
    /// @param erc20 The address of the ERC20 token required to vote.
    function createPoll(
        string memory question,
        string[] memory options,
        uint256 startTime,
        uint256 endTime,
        address erc20
    ) external payable {
        require(options.length >= 2, PollCreationErrors.InsufficientNumberOfOptions());
        require(msg.value >= s_minimumFeeInETH, PollCreationErrors.InsufficientFee(s_minimumFeeInETH, msg.value));
        require(endTime > block.timestamp, PollCreationErrors.EndTimeMustBeAFutureTime());
        require(erc20.code.length > 0, PollCreationErrors.NotAValidERC20ContractAddress());
        Poll memory poll = Poll(question, options, startTime, endTime, erc20, msg.sender);
        s_idToPoll[s_polls.length + 1] = poll;
        s_polls.push(poll);
        emit PollCreated(msg.sender, erc20, question);
    }

    /// @notice Returns the minimum ETH fee required to create a poll.
    /// @return The minimum fee in wei.
    function getMinFee() external view returns (uint256) {
        return s_minimumFeeInETH;
    }

    /// @notice Returns all polls that have been created.
    /// @return An array of Poll structs.
    function getAllPolls() external view returns (Poll[] memory) {
        return s_polls;
    }

    /// @notice Returns poll details for a given poll ID.
    /// @param pollId The ID of the poll to query.
    /// @return The Poll struct for the given ID.
    function getPollById(uint256 pollId) external view returns (Poll memory) {
        return s_idToPoll[pollId];
    }
}
