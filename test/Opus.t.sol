// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Opus} from "src/Opus.sol";

contract OpusTest is Test {
    uint256 public constant ROUND_DURATION = 14 days;
    uint256 public immutable startTime = block.timestamp;
    Opus public immutable opus;

    constructor() {
        opus = new Opus(ROUND_DURATION, startTime);
    }

    /*//////////////////////////////////////////////////////////////
                            constructor
    //////////////////////////////////////////////////////////////*/

    function testConstructor() external view {
        assertEq(opus.roundDuration(), ROUND_DURATION);
        assertEq(opus.startTime(), startTime);
    }

    function testConstructorFuzz(
        uint256 roundDuration_,
        uint256 startTime_
    ) external {
        Opus opus_ = new Opus(roundDuration_, startTime_);

        assertEq(opus_.roundDuration(), roundDuration_);
        assertEq(opus_.startTime(), startTime_);
    }
}
