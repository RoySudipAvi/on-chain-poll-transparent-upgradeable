//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console, Token, PollCreation, IERC20, PollCreationTest} from "test/unit/PollCreation.t.sol";
import {VotingV1, VotingV1Deployment} from "script/VotingV1.s.sol";
import {VotingV2, HelperConfig, VotingV2Deployment} from "script/VotingV2.s.sol";
import {IPoll} from "src/interfaces/IPoll.sol";
import {VotingErrors} from "src/interfaces/IErrors.sol";
import {
    ProxyAdmin,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract VotingV1Test is PollCreationTest {
    VotingV1 private s_voting;
    address private s_proxy;

    event VoteCasted(uint256 indexed pollId, uint256 indexed optionVoted, address indexed voter);
    event VoteCastedV2(uint256 indexed pollId, uint256 indexed optionVoted, address indexed voter, uint256 numVotes);

    function setUp() public override {
        super.setUp();

        VotingV1Deployment deployVotingV1 = new VotingV1Deployment();
        (s_voting, s_proxy) = deployVotingV1.run(address(s_pollCreation));
    }

    function testVotingRevertIfInsufficientERC20Balance() external {
        vm.warp(block.timestamp + 3);
        vm.expectRevert(VotingErrors.NotEnoughTokenBalance.selector);
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 2));
    }

    function testVotingUserVoteUpdate() external {
        uint256 feePaid = 0.005 ether;
        deal(address(0x023), 1 ether);
        vm.startPrank(address(0x023));
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
        vm.stopPrank();
        vm.warp(block.timestamp + 3);
        address voter = address(0x011);
        deal(address(s_erc20), voter, 5e18);
        vm.startPrank(voter);
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 2));
        vm.stopPrank();
        (, bytes memory data) = s_proxy.call(abi.encodeWithSignature("userVote(address,uint256)", voter, 1));
        uint256 optionIndex = abi.decode(data, (uint256));
        assertEq(optionIndex, 2);
    }

    function testVotingOptionNumVotes() external {
        uint256 feePaid = 0.005 ether;
        deal(address(0x023), 1 ether);
        vm.startPrank(address(0x023));
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
        vm.stopPrank();
        vm.warp(block.timestamp + 3);
        for (uint256 i = 1; i < 6; i++) {
            deal(address(s_erc20), address(uint160(i)), 5e18);
        }
        vm.prank(address(1));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 2));
        vm.prank(address(2));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 0));
        vm.prank(address(3));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 0));
        vm.prank(address(4));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 3));
        vm.prank(address(5));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 0));

        (, bytes memory data) = s_proxy.call(abi.encodeWithSignature("votesPerOption(uint256,uint256)", 1, 0));
        uint256 optionVotes = abi.decode(data, (uint256));
        assertEq(optionVotes, 3);
    }

    function testImplementationUpgrade() external {
        uint256 feePaid = 0.005 ether;
        deal(address(0x023), 1 ether);
        vm.startPrank(address(0x023));
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
        vm.stopPrank();
        vm.warp(block.timestamp + 3);
        address voter = address(0x011);
        deal(address(s_erc20), voter, 5e18);
        vm.startPrank(voter);
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 2));
        vm.stopPrank();
        (, bytes memory data) = s_proxy.call(abi.encodeWithSignature("userVote(address,uint256)", voter, 1));
        uint256 optionIndex = abi.decode(data, (uint256));
        bytes32 proxyAdminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 proxyAdminSlotValue = vm.load(s_proxy, proxyAdminSlot);
        address proxyAdmin = address(uint160(uint256(proxyAdminSlotValue)));
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

        VotingV2Deployment deployv2 = new VotingV2Deployment();
        (VotingV2 voting, HelperConfig.Config memory helperconfig) = deployv2.run();
        vm.startPrank(helperconfig.deployer);
        proxyAdmin.call(
            abi.encodeWithSignature(
                "upgradeAndCall(address,address,bytes)", ITransparentUpgradeableProxy(s_proxy), address(voting), ""
            )
        );

        vm.stopPrank();
        bytes32 implementationSlotValueAfterUpgrade = vm.load(s_proxy, implementationSlot);
        address implentationAfterUpgrade = address(uint160(uint256(implementationSlotValueAfterUpgrade)));

        assertEq(implentationAfterUpgrade, address(voting));
    }

    function testUserVotePostUpgrade() external {
        uint256 feePaid = 0.005 ether;
        deal(address(0x023), 1 ether);
        vm.startPrank(address(0x023));
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
        vm.stopPrank();

        bytes32 proxyAdminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 proxyAdminSlotValue = vm.load(s_proxy, proxyAdminSlot);
        address proxyAdmin = address(uint160(uint256(proxyAdminSlotValue)));
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        VotingV2Deployment deployv2 = new VotingV2Deployment();
        (VotingV2 voting, HelperConfig.Config memory helperconfig) = deployv2.run();
        vm.startPrank(helperconfig.deployer);
        proxyAdmin.call(
            abi.encodeWithSignature(
                "upgradeAndCall(address,address,bytes)", ITransparentUpgradeableProxy(s_proxy), address(voting), ""
            )
        );

        vm.stopPrank();
        vm.warp(block.timestamp + 3);
        address voter = address(0x011);
        deal(address(s_erc20), voter, 7e18);
        vm.startPrank(voter);
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 0));
        vm.stopPrank();
        (, bytes memory optionData) = s_proxy.call(abi.encodeWithSignature("userVote(address,uint256)", voter, 1));
        uint256 optionIndex = abi.decode(optionData, (uint256));
        (, bytes memory numOfVotesData) =
            s_proxy.call(abi.encodeWithSignature("userVoteNumVotes(address,uint256,uint256)", voter, 1, 0));
        uint256 numVotes = abi.decode(numOfVotesData, (uint256));
        assertEq(optionIndex, 0);
        assertEq(numVotes, 7);
    }

    function testOptionNumVotesPostUpgrade() external {
        uint256 feePaid = 0.005 ether;
        deal(address(0x023), 1 ether);
        vm.startPrank(address(0x023));
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
        vm.stopPrank();
        bytes32 proxyAdminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 proxyAdminSlotValue = vm.load(s_proxy, proxyAdminSlot);
        address proxyAdmin = address(uint160(uint256(proxyAdminSlotValue)));
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        VotingV2Deployment deployv2 = new VotingV2Deployment();
        (VotingV2 voting, HelperConfig.Config memory helperconfig) = deployv2.run();
        vm.startPrank(helperconfig.deployer);
        proxyAdmin.call(
            abi.encodeWithSignature(
                "upgradeAndCall(address,address,bytes)", ITransparentUpgradeableProxy(s_proxy), address(voting), ""
            )
        );

        vm.stopPrank();
        vm.warp(block.timestamp + 3);
        for (uint256 i = 1; i < 6; i++) {
            deal(address(s_erc20), address(uint160(i)), 8e18);
        }
        vm.prank(address(1));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 2));
        vm.prank(address(2));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 0));
        vm.prank(address(3));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 0));
        vm.prank(address(4));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 3));
        vm.prank(address(5));
        s_proxy.call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 0));
        (, bytes memory data) = s_proxy.call(abi.encodeWithSignature("votesPerOption(uint256,uint256)", 1, 0));
        uint256 optionVotes = abi.decode(data, (uint256));
        assertEq(optionVotes, 24);
    }
}
