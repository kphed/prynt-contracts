// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "solady/utils/LibString.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {CallbackConsumer} from "infernet-sdk/consumer/Callback.sol";

contract Prynt is Ownable, CallbackConsumer, ERC721 {
    using LibString for uint256;

    string private constant _COMPUTE_CONTAINER_ID = "prompt-to-nft";
    address private constant _COMPUTE_PAYMENT_TOKEN = address(0);
    uint16 private constant _COMPUTE_REDUNDANCY = 1;
    address private constant _COMPUTE_PAYER = address(0);
    address private constant _COMPUTE_PROOF_VERIFIER = address(0);

    /// @notice Duration of each round in seconds.
    uint256 public immutable roundDuration;

    /// @notice Base token URI.
    string public baseURI = "";

    /// @notice Next token identifier.
    uint256 public nextTokenId = 1;

    /// @notice Timestamp of when the next round can start.
    uint256 public nextRoundStart = block.timestamp;

    /// @notice Address with the ability to start the next round.
    address public roundLeader = msg.sender;

    /// @notice Token metadata by id.
    mapping(uint256 tokenId => string metadataHash) public tokenMetadata;

    event SetBaseURI(string baseURI);
    event StartRound(uint32 subscriptionId);

    error TooEarly();
    error NotLeader();

    constructor(
        uint256 roundDuration_,
        address registry
    ) CallbackConsumer(registry) {
        roundDuration = roundDuration_;

        _initializeOwner(msg.sender);
    }

    /**
     * @notice Handle compute request output.
     * @param  output  bytes  Compute request output.
     */
    function _receiveCompute(
        uint32,
        uint32,
        uint16,
        address,
        bytes calldata,
        bytes calldata output,
        bytes calldata,
        bytes32,
        uint256
    ) internal override {
        (, bytes memory processedOutput) = abi.decode(output, (bytes, bytes));
        tokenMetadata[nextTokenId] = abi.decode(processedOutput, (string));

        _mint(address(this), nextTokenId);

        nextRoundStart = block.timestamp + roundDuration;
        nextTokenId += 1;
        roundLeader = address(0);
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
        return string.concat(baseURI, tokenMetadata[id]);
    }

    /**
     * @notice Start a round.
     * @param  prompt          string   Token identifier.
     * @param  paymentAmount   uint256  Compute request payment amount.
     * @return subscriptionId  uint32   Compute request identifier.
     */
    function startRound(
        string calldata prompt,
        uint256 paymentAmount
    ) external returns (uint32 subscriptionId) {
        if (block.timestamp < nextRoundStart) revert TooEarly();
        if (msg.sender != roundLeader) revert NotLeader();

        subscriptionId = _requestCompute(
            _COMPUTE_CONTAINER_ID,
            abi.encode(prompt),
            _COMPUTE_REDUNDANCY,
            _COMPUTE_PAYMENT_TOKEN,
            paymentAmount,
            _COMPUTE_PAYER,
            _COMPUTE_PROOF_VERIFIER
        );

        emit StartRound(subscriptionId);
    }
}
