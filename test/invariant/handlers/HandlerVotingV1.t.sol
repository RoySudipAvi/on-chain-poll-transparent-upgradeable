//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IPoll} from "src/interfaces/IPoll.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HandlerVotingV1 is Test {
    address private s_pollCreationFactory;
    address private s_proxy;
    address private s_token;
    uint256 private s_totalVoters;

    constructor(address erc20, address proxy, address pollCreationFactory) {
        s_pollCreationFactory = pollCreationFactory;
        s_proxy = proxy;
        s_token = erc20;
    }

    function vote(uint256 pollId, uint256 optionIndex, uint256 timestamp, address voter) external {
        pollId = bound(pollId, 1, 1);
        IPoll.Poll memory poll = IPoll(s_pollCreationFactory).getPollById(pollId);
        optionIndex = bound(optionIndex, 0, poll.options.length);
        timestamp = bound(timestamp, poll.startTime, poll.endTime);
        vm.warp(timestamp);
        vm.assume(voter != address(0));
        deal(s_token, voter, 5e18);
        (bool success, bytes memory data) =
            s_proxy.call(abi.encodeWithSignature("hasUserVoted(address,uint256)", voter, pollId));
        if (success) {
            bool voted = abi.decode(data, (bool));
            if (!voted) {
                vm.prank(voter);
                (bool successVote,) =
                    s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", pollId, optionIndex));
                s_totalVoters = successVote ? s_totalVoters + 1 : s_totalVoters;
            }
        } else {
            return;
        }
    }

    function getTotalVoters() external view returns (uint256) {
        return s_totalVoters;
    }
}
