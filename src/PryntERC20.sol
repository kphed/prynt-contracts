// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UniswapV3Pool} from "lib/v3-core/contracts/UniswapV3Pool.sol";
import {TickMath} from "lib/v3-core/contracts/libraries/TickMath.sol";
import {INonfungiblePositionManager} from "lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ERC20} from "solady/tokens/ERC20.sol";

contract PryntERC20 is ERC20 {
    string private _name;
    string private _symbol;

    /// @notice Timestamp of when the round will end.
    uint256 public immutable roundEnd;

    /// @notice Uniswap liquidity pool.
    address public immutable pool;

    /// @notice Address of the round leader.
    address public roundLeader;

    event NewLeader(address leader);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 roundEnd_,
        address positionManager,
        address quoteToken,
        uint24 poolFee,
        uint160 sqrtPriceX96,
        address treasury
    ) {
        _name = name_;
        _symbol = symbol_;
        roundEnd = roundEnd_;
        pool = INonfungiblePositionManager(positionManager)
            .createAndInitializePoolIfNecessary(
                address(this),
                quoteToken,
                poolFee,
                sqrtPriceX96
            );
        int24 tickSpacing = UniswapV3Pool(pool).tickSpacing();

        _mint(address(this), totalSupply());
        _approve(address(this), positionManager, type(uint256).max);
        INonfungiblePositionManager(positionManager).mint(
            INonfungiblePositionManager.MintParams(
                address(this),
                quoteToken,
                poolFee,
                TickMath.getTickAtSqrtRatio(sqrtPriceX96),
                (TickMath.MAX_TICK / tickSpacing) * tickSpacing,
                totalSupply(),
                0,
                0,
                0,
                treasury,
                block.timestamp
            )
        );
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
     * @notice Check whether the token transfer recipient has the highest balance.
     * @param  to  address  Token transfer recipient.
     */
    function _afterTokenTransfer(
        address,
        address to,
        uint256
    ) internal override {
        if (
            block.timestamp < roundEnd &&
            pool != to &&
            balanceOf(to) > balanceOf(roundLeader)
        ) {
            roundLeader = to;

            emit NewLeader(to);
        }
    }
}
