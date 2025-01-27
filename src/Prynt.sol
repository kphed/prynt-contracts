// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "solady/utils/LibString.sol";
import {CallbackConsumer} from "infernet-sdk/consumer/Callback.sol";
import {PryntERC721} from "src/PryntERC721.sol";
import {PryntERC20} from "src/PryntERC20.sol";

contract Prynt is CallbackConsumer, PryntERC721 {
    using LibString for uint256;

    string private constant _COMPUTE_CONTAINER_ID = "prompt-to-nft";
    uint16 private constant _COMPUTE_REDUNDANCY = 1;
    address private constant _COMPUTE_PAYMENT_TOKEN = address(0);
    address private constant _COMPUTE_PAYER = address(0);
    address private constant _COMPUTE_PROOF_VERIFIER = address(0);

    /// @notice Address of the DAO treasury.
    address public immutable treasury;

    /// @notice LP manager contract for deploying pools, adding liquidity, and collecting fees.
    address public immutable uniswapPositionManager;

    /// @notice Duration of each round in seconds.
    uint256 public immutable roundDuration;

    /// @notice Timestamp of when the next round can start.
    uint256 public nextRoundStart = block.timestamp;

    /// @notice Address with the ability to start the next round.
    address public roundLeader = msg.sender;

    /// @notice Round id.
    uint256 public roundId = 1;

    /// @notice Pending compute requests by round id.
    mapping(uint256 roundId => uint256 subscriptionId) public pendingRequests;

    /// @notice Associated ERC20 token contract by round id.
    mapping(uint256 roundId => PryntERC20) public fungibleTokens;

    event StartRound(
        uint256 indexed nextRoundId,
        uint32 indexed subscriptionId
    );

    error TooEarly();
    error NotLeader();
    error StaleRequest();

    constructor(
        address registry,
        address treasury_,
        address uniswapPositionManager_,
        uint256 roundDuration_,
        string memory initialPrompt,
        uint256 initialPaymentAmount
    ) CallbackConsumer(registry) {
        treasury = treasury_;
        uniswapPositionManager = uniswapPositionManager_;
        roundDuration = roundDuration_;

        _startRound(initialPrompt, initialPaymentAmount);
    }

    /**
     * @notice Handle compute request fulfillment.
     * @param  subscriptionId  uint32  Compute request id.
     * @param  output          bytes   Compute request output.
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
        uint256 currentRoundId = roundId;

        // Prevent previous compute requests for the current round id from modifying state.
        if (pendingRequests[currentRoundId] != subscriptionId)
            revert StaleRequest();

        (, bytes memory processedOutput) = abi.decode(output, (bytes, bytes));
        (
            string memory metadataHash,
            bytes32 deploymentSalt,
            address quoteToken,
            uint24 poolFee,
            uint160 sqrtPriceX96
        ) = abi.decode(
                processedOutput,
                (string, bytes32, address, uint24, uint160)
            );
        tokenMetadata[currentRoundId] = metadataHash;

        // Prevent the current round leader from calling `startRound` for the next round (unless they win again).
        roundLeader = address(0);

        unchecked {
            // Won't overflow until `_requestCompute` is called ~9.57275870017495e+70 times.
            nextRoundStart = block.timestamp + roundDuration;

            // Won't overflow until `_requestCompute` is called ~1.157920892373162e+77 times.
            ++roundId;
        }

        _mint(address(this), currentRoundId);

        fungibleTokens[currentRoundId] = new PryntERC20{salt: deploymentSalt}(
            currentRoundId,
            nextRoundStart,
            uniswapPositionManager,
            quoteToken,
            poolFee,
            sqrtPriceX96,
            treasury
        );
    }

    /**
     * @notice Start a round.
     * @param  prompt          string   Token id.
     * @param  paymentAmount   uint256  Compute request payment amount.
     * @return subscriptionId  uint32   Compute request id.
     */
    function _startRound(
        string memory prompt,
        uint256 paymentAmount
    ) internal returns (uint32 subscriptionId) {
        subscriptionId = _requestCompute(
            _COMPUTE_CONTAINER_ID,
            abi.encode(prompt),
            _COMPUTE_REDUNDANCY,
            _COMPUTE_PAYMENT_TOKEN,
            paymentAmount,
            _COMPUTE_PAYER,
            _COMPUTE_PROOF_VERIFIER
        );
        uint256 _roundId = roundId;
        pendingRequests[_roundId] = subscriptionId;

        emit StartRound(_roundId, subscriptionId);
    }

    /**
     * @notice Start a round.
     * @param  prompt          string   Token id.
     * @param  paymentAmount   uint256  Compute request payment amount.
     */
    function startRound(
        string calldata prompt,
        uint256 paymentAmount
    ) external returns (uint32) {
        if (block.timestamp < nextRoundStart) revert TooEarly();
        if (msg.sender != roundLeader) revert NotLeader();

        return _startRound(prompt, paymentAmount);
    }
}
