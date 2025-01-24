// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Prynt} from "src/Prynt.sol";

contract PryntScript is Script {
    address private constant _REGISTRY =
        0x663F3ad617193148711d28f5334eE4Ed07016602;

    function run() public {
        vm.broadcast(vm.envUint("PRIVATE_KEY"));

        new Prynt(14 days, 0, _REGISTRY);
    }
}
