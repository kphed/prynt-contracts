// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Opus {
    /// @dev The duration of each trading competition in seconds.
    uint256 public immutable roundDuration;

    /// @dev The timestamp of when the first trading competition starts.
    uint256 public immutable startTime;

    constructor(uint256 roundDuration_, uint256 startTime_) {
        roundDuration = roundDuration_;
        startTime = startTime_;
    }
}
