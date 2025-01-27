// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Prynt} from "src/Prynt.sol";
import {InfernetSDK} from "test/InfernetSDK.sol";

contract PryntTest is InfernetSDK {
    address public constant TREASURY = address(0);
    address public constant POSITION_MANAGER = address(0);
    uint256 public constant ROUND_DURATION = 14 days;
    string public constant INITIAL_PROMPT =
        "Retro polaroid of an oldschool printer.";
    uint256 public constant INITIAL_PAYMENT_AMOUNT = 0;
    uint256 public immutable startTime = block.timestamp;
    Prynt public immutable prynt;

    constructor() {
        prynt = new Prynt(
            address(registry),
            TREASURY,
            POSITION_MANAGER,
            ROUND_DURATION,
            INITIAL_PROMPT,
            INITIAL_PAYMENT_AMOUNT
        );
    }

    /*//////////////////////////////////////////////////////////////
                            constructor
    //////////////////////////////////////////////////////////////*/

    function testConstructor() external view {
        assertEq(prynt.roundDuration(), ROUND_DURATION);
    }

    function testConstructorFuzz(
        uint256 roundDuration_,
        address msgSender
    ) external {
        vm.prank(msgSender);

        Prynt fuzzPrynt = new Prynt(
            address(registry),
            TREASURY,
            POSITION_MANAGER,
            roundDuration_,
            INITIAL_PROMPT,
            INITIAL_PAYMENT_AMOUNT
        );

        assertEq(fuzzPrynt.roundDuration(), roundDuration_);
    }
}
