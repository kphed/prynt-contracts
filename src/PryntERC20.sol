// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "solady/utils/LibString.sol";
import {UniswapV3Pool} from "src/v3-core/contracts/UniswapV3Pool.sol";
import {TickMath} from "src/v3-core/contracts/libraries/TickMath.sol";
import {INonfungiblePositionManager} from "src/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {ERC20} from "solady/tokens/ERC20.sol";

contract PryntERC20 is ERC20 {
    string private _name;
    string private _symbol;

    /// @notice Prynt DAO NFT.
    ERC721 public immutable prynt;

    /// @notice Round and NFT token id.
    uint256 public immutable round;

    /// @notice Timestamp of when the round will end.
    uint256 public immutable roundEnd;

    /// @notice Uniswap liquidity pool.
    address public immutable pool;

    /// @notice Address of the round leader.
    address public roundLeader;

    event NewLeader(address leader);
    event ClaimNFT();

    error CannotTransfer();
    error TooEarly();
    error NotLeader();

    constructor(
        uint256 round_,
        uint256 roundEnd_,
        address positionManager,
        address quoteToken,
        uint24 poolFee,
        uint160 sqrtPriceX96,
        address treasury
    ) {
        string memory roundStr = LibString.toString(round_);
        _name = string.concat("Prynt Round ", roundStr);
        _symbol = string.concat("pryntROUND-", roundStr);
        prynt = ERC721(msg.sender);
        round = round_;
        roundEnd = roundEnd_;
        pool = INonfungiblePositionManager(positionManager)
            .createAndInitializePoolIfNecessary(
                address(this),
                quoteToken,
                poolFee,
                sqrtPriceX96
            );
        int24 tickSpacing = UniswapV3Pool(pool).tickSpacing();
        uint256 _totalSupply = totalSupply();

        _mint(address(this), _totalSupply);
        _approve(address(this), positionManager, type(uint256).max);
        INonfungiblePositionManager(positionManager).mint(
            INonfungiblePositionManager.MintParams(
                address(this),
                quoteToken,
                poolFee,
                TickMath.getTickAtSqrtRatio(sqrtPriceX96),
                (TickMath.MAX_TICK / tickSpacing) * tickSpacing,
                _totalSupply,
                0,
                0,
                0,
                treasury,
                block.timestamp
            )
        );
    }

    /**
     * @notice Check whether the token recipient has the highest balance if the round has not ended.
     * @param  from  address  Token sender.
     * @param  to    address  Token recipient.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        // If the round is over, the leader cannot transfer tokens unless they are burning.
        if (
            block.timestamp >= roundEnd &&
            from == roundLeader &&
            to != address(0)
        ) revert CannotTransfer();
    }

    /**
     * @notice Check whether the token recipient has the highest balance if the round has not ended.
     * @param  to  address  Token recipient.
     */
    function _afterTokenTransfer(
        address,
        address to,
        uint256
    ) internal override {
        if (block.timestamp < roundEnd) {
            // Do not run the balance comparison logic if the recipient is any of the following addresses.
            if (to == address(this) || to == pool) return;

            if (balanceOf(to) > balanceOf(roundLeader)) {
                roundLeader = to;

                emit NewLeader(to);
            }
        }
    }

    /**
     * @notice Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Claim the Prynt DAO NFT.
     */
    function claimNFT() external {
        if (block.timestamp < roundEnd) revert TooEarly();
        if (msg.sender != roundLeader) revert NotLeader();

        // Burn the round leader's tokens as a consolation prize to those who didn't win.
        _burn(msg.sender, balanceOf(msg.sender));

        prynt.safeTransferFrom(address(this), msg.sender, 0);

        emit ClaimNFT();
    }
}
