//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Token, TokenDeployment} from "script/Token.s.sol";
import {PollCreation, PollCreationDeployment} from "script/PollCreation.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PollCreationErrors} from "src/interfaces/IErrors.sol";

contract PollCreationTest is Test {
    Token internal s_token;
    PollCreation internal s_pollCreation;
    string internal s_question;
    string[] internal s_options;
    uint256 internal s_startTime;
    uint256 internal s_endTime;
    address internal s_erc20;

    event PollCreated(address indexed owner, address indexed erc20, string question);

    function setUp() public virtual {
        TokenDeployment tokenDeploy = new TokenDeployment();
        s_token = tokenDeploy.run();
        PollCreationDeployment pollCreationDeploy = new PollCreationDeployment();
        s_pollCreation = pollCreationDeploy.run();
        s_question = "Who is going to win Champions League 2025-26?";
        s_options = new string[](6);
        s_options[0] = "Liverpool";
        s_options[1] = "Barcelona";
        s_options[2] = "PSG";
        s_options[3] = "Real Madrid";
        s_options[4] = "Manchester City";
        s_options[5] = "Bayern Munich";
        s_startTime = block.timestamp + 1;
        s_endTime = block.timestamp + 864000;
        s_erc20 = address(s_token);
    }

    function testRevertPollCreationIfInsufficientFee() external {
        uint256 feePaid = 0.0049 ether;
        vm.expectRevert(
            abi.encodeWithSelector(PollCreationErrors.InsufficientFee.selector, s_pollCreation.getMinFee(), feePaid)
        );
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
    }

    function testRevertPollCreationIfAddressisNotValidERC20Contract() external {
        uint256 feePaid = 0.005 ether;
        address erc20 = address(0x0039);
        vm.expectRevert(PollCreationErrors.NotAValidERC20ContractAddress.selector);
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, erc20);
    }

    function testPollCreationPollEmitEvent() external {
        uint256 feePaid = 0.005 ether;
        deal(address(0x023), 1 ether);
        vm.startPrank(address(0x023));
        vm.expectEmit(true, true, false, true);
        emit PollCreated(address(0x023), s_erc20, s_question);
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
        vm.stopPrank();
    }

    function testPollCreationGetPollById() external {
        uint256 feePaid = 0.005 ether;
        deal(address(0x023), 1 ether);
        vm.startPrank(address(0x023));
        s_pollCreation.createPoll{value: feePaid}(s_question, s_options, s_startTime, s_endTime, s_erc20);
        vm.stopPrank();
        string memory question = "Who is going to win La Liga 2025-26?";
        string[] memory options = new string[](4);
        options[0] = "Barcelona";
        options[1] = "Real Madrid";
        options[2] = "Atletico Madrid";
        options[3] = "Villareal";
        uint256 startTime = block.timestamp + 1;
        uint256 endTime = block.timestamp + 86400;
        address erc20 = address(s_token);
        deal(address(0x039), 1 ether);
        vm.startPrank(address(0x039));
        s_pollCreation.createPoll{value: feePaid}(question, options, startTime, endTime, erc20);
        vm.stopPrank();
        PollCreation.Poll memory poll = s_pollCreation.getPollById(2);
        //console.log(poll.owner);
        assertEq(poll.owner, address(0x039));
    }
}
