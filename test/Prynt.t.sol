// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Prynt} from "src/Prynt.sol";
import {InfernetSDK} from "test/InfernetSDK.sol";

contract PryntTest is InfernetSDK {
    uint256 public constant ROUND_DURATION = 14 days;
    uint256 public immutable startTime = block.timestamp;
    Prynt public immutable prynt;

    constructor() {
        prynt = new Prynt(ROUND_DURATION, address(registry));
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

        Prynt fuzzPrynt = new Prynt(roundDuration_, address(registry));

        assertEq(fuzzPrynt.roundDuration(), roundDuration_);
    }
}
