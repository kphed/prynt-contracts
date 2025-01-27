// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";

contract PryntERC721 is Ownable, ERC721, Votes {
    /// @notice EIP712 domain name (the user readable name of the signing domain).
    string private constant _EIP712_DOMAIN_NAME = "Prynt DAO";

    /// @notice EIP712 domain version (the current major version of the signing domain).
    string private constant _EIP712_DOMAIN_VERSION = "1";

    /// @notice Voting unit.
    uint256 private constant _VOTE_TRANSFER_UNIT = 1;

    /// @notice Base token URI.
    string public baseURI = "";

    /// @notice Token metadata by id.
    mapping(uint256 tokenId => string metadataHash) public tokenMetadata;

    event SetBaseURI(string baseURI);

    constructor() EIP712(_EIP712_DOMAIN_NAME, _EIP712_DOMAIN_VERSION) {
        _initializeOwner(msg.sender);
    }

    /**
     * @notice Update voting units to reflect the token transfer.
     * @param  from  address  Sender.
     * @param  to    address  Recipient.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        _transferVotingUnits(from, to, _VOTE_TRANSFER_UNIT);
    }

    /**
     * @notice Returns the balance of `account`.
     * @param  account  address  Account.
     */
    function _getVotingUnits(
        address account
    ) internal view override returns (uint256) {
        return balanceOf(account);
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
