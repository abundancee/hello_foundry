// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {saveERCandEther} from "../src/saveERCandEther.sol";

contract saveERCandEtherScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new saveERCandEther();
        vm.stopBroadcast();
    }
}
