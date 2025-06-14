//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {VotingV2} from "src/contracts/VotingV2.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract VotingV2Deployment is Script {
    function run() external returns (VotingV2, HelperConfig.Config memory config) {
        HelperConfig helper = new HelperConfig();
        config = helper.getConfigByChainId();
        vm.startBroadcast(config.deployer);
        VotingV2 voting = new VotingV2();
        vm.stopBroadcast();
        return (voting, config);
    }
}
