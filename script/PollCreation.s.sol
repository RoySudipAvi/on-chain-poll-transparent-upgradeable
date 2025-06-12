//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {PollCreation} from "src/contracts/PollCreation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract PollCreationDeployment is Script {
    uint256 public constant MIN_FEE = 5e15;

    function run() external returns (PollCreation) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.Config memory config = helper.getConfigByChainId();
        vm.startBroadcast(config.deployer);
        PollCreation pollCreation = new PollCreation(MIN_FEE);
        vm.stopBroadcast();
        return pollCreation;
    }
}
