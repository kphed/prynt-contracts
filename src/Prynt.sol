// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "solady/utils/LibString.sol";
import {CallbackConsumer} from "infernet-sdk/consumer/Callback.sol";
import {PryntERC721} from "src/PryntERC721.sol";
import {PryntERC20} from "src/PryntERC20.sol";

contract Prynt is CallbackConsumer, PryntERC721 {
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

    /// @notice Round id.
    uint256 public roundId = 0;

    /// @notice Pending compute requests by round id.
    mapping(uint256 roundId => uint256 subscriptionId) public pendingRequests;

    /// @notice Associated ERC20 token contract by round id.
    mapping(uint256 roundId => address fungibleToken) public fungibleTokens;

    event InitiateNewRound(
        address indexed roundLeader,
        uint256 indexed roundId,
        uint32 indexed subscriptionId
    );
    event NewRound(uint256 indexed roundId, address indexed fungibleToken);

    error TooEarly();
    error NotLeader();
    error StaleRequest();

    constructor(
        address registry,
        address treasury_,
        address uniswapPositionManager_,
        uint256 roundDuration_
    ) CallbackConsumer(registry) {
        treasury = treasury_;
        uniswapPositionManager = uniswapPositionManager_;
        roundDuration = roundDuration_;
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
        // Prevent previous compute requests for the current round id from modifying state, ensuring
        // that only the most recent `initiateNewRound` call is respected. This is useful in the event where
        // the leader wants to change their prompt, or the compute request needs a higher payment amount.
        if (pendingRequests[roundId] != subscriptionId) revert StaleRequest();

        (, bytes memory processedOutput) = abi.decode(output, (bytes, bytes));
        (
            string memory metadataHash,
            // @dev Unsafe to delegate computing of fungible token and LP-related params in production.
            bytes32 deploymentSalt,
            address quoteToken,
            uint24 poolFee,
            uint160 sqrtPriceX96
        ) = abi.decode(
                processedOutput,
                (string, bytes32, address, uint24, uint160)
            );

        unchecked {
            // Won't overflow until `_requestCompute` is called ~1.157920892373162e+77 times.
            uint256 _roundId = ++roundId;

            tokenMetadata[_roundId] = metadataHash;
            fungibleTokens[_roundId] = address(
                new PryntERC20{salt: deploymentSalt}(
                    _roundId,
                    block.timestamp + roundDuration,
                    uniswapPositionManager,
                    quoteToken,
                    poolFee,
                    sqrtPriceX96,
                    treasury
                )
            );

            // Mint the NFT for the ERC20 token contract which will handle its dispersal to the winner.
            _mint(fungibleTokens[_roundId], _roundId);

            emit NewRound(_roundId, fungibleTokens[_roundId]);
        }
    }

    /**
     * @notice Initiate a new round.
     * @param  prompt          string   NFT image prompt.
     * @param  paymentAmount   uint256  Compute request payment amount.
     * @return subscriptionId  uint32   Compute request id.
     */
    function initiateNewRound(
        string calldata prompt,
        uint256 paymentAmount
    ) external returns (uint32 subscriptionId) {
        uint256 _roundId = roundId;

        // Allow the contract owner to initiate a new round to kickstart the game,
        // or in the event that the current round leader hasn't done so in a timely manner.
        if (msg.sender != owner()) {
            PryntERC20 fungibleToken = PryntERC20(fungibleTokens[_roundId]);

            if (block.timestamp < fungibleToken.roundEnd()) revert TooEarly();
            if (msg.sender != fungibleToken.roundLeader()) revert NotLeader();
        }

        subscriptionId = _requestCompute(
            _COMPUTE_CONTAINER_ID,
            abi.encode(prompt),
            _COMPUTE_REDUNDANCY,
            _COMPUTE_PAYMENT_TOKEN,
            paymentAmount,
            _COMPUTE_PAYER,
            _COMPUTE_PROOF_VERIFIER
        );
        pendingRequests[_roundId] = subscriptionId;

        emit InitiateNewRound(msg.sender, _roundId, subscriptionId);
    }
}
