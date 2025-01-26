// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CallbackConsumer} from "infernet-sdk/consumer/Callback.sol";
import {PryntNFT} from "src/PryntNFT.sol";

contract Prynt is CallbackConsumer, PryntNFT {
    string private constant _COMPUTE_CONTAINER_ID = "prompt-to-nft";
    address private constant _COMPUTE_PAYMENT_TOKEN = address(0);
    uint16 private constant _COMPUTE_REDUNDANCY = 1;
    address private constant _COMPUTE_PAYER = address(0);
    address private constant _COMPUTE_PROOF_VERIFIER = address(0);

    /// @notice Duration of each round in seconds.
    uint256 public immutable roundDuration;

    /// @notice Timestamp of when the next round can start.
    uint256 public nextRoundStart = block.timestamp;

    /// @notice Address with the ability to start the next round.
    address public roundLeader = msg.sender;

    /// @notice Pending compute requests by token id.
    mapping(uint256 tokenId => uint256 subscriptionId) public pendingRequests;

    event StartRound(uint256 nextTokenId, uint32 subscriptionId);

    error TooEarly();
    error NotLeader();
    error StaleRequest();

    constructor(
        uint256 roundDuration_,
        address registry
    ) CallbackConsumer(registry) {
        roundDuration = roundDuration_;
    }

    /**
     * @notice Handle compute request output.
     * @param  output  bytes  Compute request output.
     */
    function _receiveCompute(
        uint32 subscriptionId,
        uint32,
        uint16,
        address,
        bytes calldata,
        bytes calldata output,
        bytes calldata,
        bytes32,
        uint256
    ) internal override {
        // Prevent previous compute requests for the current `nextTokenId` from modifying state.
        if (pendingRequests[nextTokenId] != subscriptionId)
            revert StaleRequest();

        (, bytes memory processedOutput) = abi.decode(output, (bytes, bytes));
        tokenMetadata[nextTokenId] = abi.decode(processedOutput, (string));

        _mint(address(this), nextTokenId);

        nextRoundStart = block.timestamp + roundDuration;
        nextTokenId += 1;
        roundLeader = address(0);
    }

    /**
     * @notice Start a round.
     * @param  prompt          string   Token id.
     * @param  paymentAmount   uint256  Compute request payment amount.
     * @return subscriptionId  uint32   Compute request id.
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
        pendingRequests[nextTokenId] = subscriptionId;

        emit StartRound(nextTokenId, subscriptionId);
    }
}
