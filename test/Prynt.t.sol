// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Prynt} from "src/Prynt.sol";

contract PryntTest is Test {
    uint256 public constant ROUND_DURATION = 14 days;
    uint256 public immutable startTime = block.timestamp;
    Prynt public immutable prynt;

    constructor() {
        prynt = new Prynt(ROUND_DURATION, startTime);
    }

    /*//////////////////////////////////////////////////////////////
                            constructor
    //////////////////////////////////////////////////////////////*/

    function testConstructor() external view {
        assertEq(prynt.roundDuration(), ROUND_DURATION);
        assertEq(prynt.startTime(), startTime);
    }

    function testConstructorFuzz(
        uint256 roundDuration_,
        uint256 startTime_,
        address msgSender
    ) external {
        vm.prank(msgSender);

        Prynt fuzzPrynt = new Prynt(roundDuration_, startTime_);

        assertEq(fuzzPrynt.roundDuration(), roundDuration_);
        assertEq(fuzzPrynt.startTime(), startTime_);
    }
}
