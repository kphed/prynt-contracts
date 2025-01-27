// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Prynt} from "src/Prynt.sol";

contract PryntScript is Script {
    address public constant REGISTRY =
        0x663F3ad617193148711d28f5334eE4Ed07016602;
    address public constant TREASURY = address(0);
    address public constant POSITION_MANAGER = address(0);
    string public constant INITIAL_PROMPT =
        "Retro polaroid of an oldschool printer.";
    uint256 public constant INITIAL_PAYMENT_AMOUNT = 0;

    function run() public {
        vm.broadcast(vm.envUint("PRIVATE_KEY"));

        new Prynt(
            REGISTRY,
            TREASURY,
            POSITION_MANAGER,
            14 days,
            INITIAL_PROMPT,
            INITIAL_PAYMENT_AMOUNT
        );
    }
}
