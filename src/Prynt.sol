// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "solady/utils/LibString.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract Prynt is Ownable, ERC721 {
    using LibString for uint256;

    /// @dev The duration of each trading competition in seconds.
    uint256 public immutable roundDuration;

    /// @dev The timestamp of when the first trading competition starts.
    uint256 public immutable startTime;

    /// @dev The base token URI.
    string public baseURI;

    event SetBaseURI(string);

    constructor(uint256 roundDuration_, uint256 startTime_) {
        roundDuration = roundDuration_;
        startTime = startTime_;

        _initializeOwner(msg.sender);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "Prynt DAO";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "PRYNT";
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseURI, id.toString());
    }
}
