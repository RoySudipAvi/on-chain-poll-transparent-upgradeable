//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IPoll} from "src/interfaces/IPoll.sol";

contract HandlerPollCreation is Test {
    address private s_token;
    address private s_pollCreationFactory;

    constructor(address erc20, address pollCreationFactory) {
        s_token = erc20;
        s_pollCreationFactory = pollCreationFactory;
    }

    function createPoll() external {
        string memory question = "Who will win Ballon D'Or 2025?";
        string[] memory options = new string[](5);
        options[0] = "MBappe";
        options[1] = "Salah";
        options[2] = "Yamal";
        options[3] = "Dembele";
        options[4] = "Raphinha";
        vm.deal(address(0x0023), 1 ether);
        vm.prank(address(0x0023));
        IPoll(s_pollCreationFactory).createPoll{value: 0.005 ether}(
            question, options, block.timestamp + 5, block.timestamp + 86400000, s_token
        );
    }
}
