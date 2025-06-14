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
import {HandlerVotingV2} from "test/invariant/handlers/HandlerVotingV2.t.sol";
import {VotingV2, HelperConfig, VotingV2Deployment} from "script/VotingV2.s.sol";
import {
    ProxyAdmin,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract InvariantVotingV2 is Test {
    Token private s_token;
    PollCreation private s_pollCreation;
    VotingV1 private s_voting;
    address private s_proxy;
    HandlerPollCreation private s_handlerPoll;
    HandlerVotingV1 private s_handlerVoting;
    HandlerVotingV2 private s_handlerVotingV2;

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

        s_handlerVotingV2 = new HandlerVotingV2(address(s_token), s_proxy, address(s_pollCreation));
        bytes32 proxyAdminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 proxyAdminSlotValue = vm.load(s_proxy, proxyAdminSlot);
        address proxyAdmin = address(uint160(uint256(proxyAdminSlotValue)));

        VotingV2Deployment deployv2 = new VotingV2Deployment();
        (VotingV2 voting, HelperConfig.Config memory helperconfig) = deployv2.run();

        vm.startPrank(helperconfig.deployer);
        proxyAdmin.call(
            abi.encodeWithSignature(
                "upgradeAndCall(address,address,bytes)", ITransparentUpgradeableProxy(s_proxy), address(voting), ""
            )
        );

        vm.stopPrank();
        targetContract(address(s_handlerVotingV2));
        //targetContract(address(s_handlerVoting));
    }

    function invariantTotalVotesSameAsTotalERC20BalanceOfVoters() external {
        //excludeContract(address(s_handlerVoting));

        IPoll.Poll memory poll = IPoll(address(s_pollCreation)).getPollById(1);
        uint256 totalVotes;
        for (uint256 i; i < poll.options.length; i++) {
            (, bytes memory data) = s_proxy.call(abi.encodeWithSignature("votesPerOption(uint256,uint256)", 1, i));
            uint256 votesPerOption = abi.decode(data, (uint256));
            totalVotes += votesPerOption;
        }

        console.log("Voters Balance: ", s_handlerVotingV2.getTotalVotersERC20Balance());
        console.log("total voters v2:", s_handlerVotingV2.getTotalVoters());
        console.log("total votes:", totalVotes);
        assertEq(totalVotes, s_handlerVotingV2.getTotalVotersERC20Balance() / 1e18);
    }
}
