//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {VotingV1} from "src/contracts/VotingV1.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract VotingV1Deployment is Script {
    function run(address pollCreation) external returns (VotingV1, address) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.Config memory config = helper.getConfigByChainId();
        vm.startBroadcast(config.deployer);
        VotingV1 voting = new VotingV1();
        bytes memory initData = abi.encodeWithSignature("initialize(address)", pollCreation);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(voting), config.deployer, initData);
        vm.stopBroadcast();
        return (voting, address(proxy));
    }
}
