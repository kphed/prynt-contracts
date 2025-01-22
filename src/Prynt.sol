// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "solady/utils/LibString.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {CallbackConsumer} from "infernet-sdk/consumer/Callback.sol";

contract Prynt is Ownable, CallbackConsumer, ERC721 {
    using LibString for uint256;

    /// @notice The duration of each round in seconds.
    uint256 public immutable roundDuration;

    /// @notice The timestamp of when the first round starts.
    uint256 public immutable startTime;

    /// @notice The base token URI.
    string public baseURI;

    event SetBaseURI(string);

    constructor(
        uint256 roundDuration_,
        uint256 startTime_,
        address registry
    ) CallbackConsumer(registry) {
        roundDuration = roundDuration_;
        startTime = startTime_;

        _initializeOwner(msg.sender);
    }

    /**
     * @notice Sets `baseURI`.
     * @param  baseURI_  string  Token base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    /**
     * @notice Returns the token collection name.
     * @return string  Token collection name.
     */
    function name() public pure override returns (string memory) {
        return "Prynt DAO";
    }

    /**
     * @notice Returns the token collection symbol.
     * @return string  Token collection symbol.
     */
    function symbol() public pure override returns (string memory) {
        return "PRYNT";
    }

    /**
     * @notice Returns the URI for a token ID.
     * @param  id  uint256  The token identifier.
     * @return     string   Token URI.
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseURI, id.toString());
    }
}
