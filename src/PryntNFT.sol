// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract PryntNFT is Ownable, ERC721 {
    /// @notice Base token URI.
    string public baseURI = "";

    /// @notice Token metadata by id.
    mapping(uint256 tokenId => string metadataHash) public tokenMetadata;

    event SetBaseURI(string baseURI);

    constructor() {
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
     * @param  id  uint256  The token id.
     * @return     string   Token URI.
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseURI, tokenMetadata[id]);
    }
}
