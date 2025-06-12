//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Token, TokenDeployment} from "script/Token.s.sol";
import {PollCreation, PollCreationDeployment} from "script/PollCreation.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VotingV1, VotingV1Deployment} from "script/VotingV1.s.sol";
import {IPoll} from "src/interfaces/IPoll.sol";
import {HandlerPollCreation} from "test/invariant/handlers/HandlerPollCreation.t.sol";
import {HandlerVotingV1} from "test/invariant/handlers/HandlerVotingV1.t.sol";

contract InvariantVotingV1 is Test {
    Token private s_token;
    PollCreation private s_pollCreation;
    VotingV1 private s_voting;
    address private s_proxy;
    HandlerPollCreation private s_handlerPoll;
    HandlerVotingV1 private s_handlerVoting;

    function setUp() external {
        TokenDeployment deployToken = new TokenDeployment();
        s_token = deployToken.run();
        PollCreationDeployment deployPollCreation = new PollCreationDeployment();
        s_pollCreation = deployPollCreation.run();
        VotingV1Deployment deployVoting = new VotingV1Deployment();
        (s_voting, s_proxy) = deployVoting.run(address(s_pollCreation));
        s_handlerPoll = new HandlerPollCreation(address(s_token), address(s_pollCreation));
        s_handlerVoting = new HandlerVotingV1(address(s_token), s_proxy, address(s_pollCreation));
        s_handlerPoll.createPoll();
        targetContract(address(s_handlerVoting));
    }

    function invariantTotalVotesIsSameAsTotalVoters() external {
        console.log("Voters: ", s_handlerVoting.getTotalVoters());
        IPoll.Poll memory poll = IPoll(address(s_pollCreation)).getPollById(1);
        uint256 totalVotes;
        for (uint256 i; i < poll.options.length; i++) {
            (, bytes memory data) = s_proxy.call(abi.encodeWithSignature("votesPerOption(uint256,uint256)", 1, i));
            uint256 votesPerOption = abi.decode(data, (uint256));
            totalVotes += votesPerOption;
        }
        assertEq(s_handlerVoting.getTotalVoters(), totalVotes);
    }
}
