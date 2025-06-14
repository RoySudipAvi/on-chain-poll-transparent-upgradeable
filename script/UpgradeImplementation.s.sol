//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {
    ProxyAdmin,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract UpgradeImplementation is Script {
    bytes32 public constant PROXYADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 public constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function run(address proxy, address implementation) external {
        bytes32 proxyAdminSlotValue = vm.load(proxy, PROXYADMIN_SLOT);
        address proxyAdmin = address(uint160(uint256(proxyAdminSlotValue)));
        bytes32 implementationSlotValue = vm.load(proxy, IMPLEMENTATION_SLOT);
        HelperConfig helper = new HelperConfig();
        HelperConfig.Config memory config = helper.getConfigByChainId();
        vm.startBroadcast(config.deployer);
        ProxyAdmin(proxyAdmin).upgradeAndCall(ITransparentUpgradeableProxy(proxy), implementation, "");
        vm.stopBroadcast();
    }
}
