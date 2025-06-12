//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {Token} from "src/contracts/Token.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract TokenDeployment is Script {
    function run() external returns (Token) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.Config memory config = helper.getConfigByChainId();
        vm.startBroadcast(config.deployer);
        Token token = new Token("Platform Demo Token", "PDT");
        vm.stopBroadcast();
        return token;
    }
}
