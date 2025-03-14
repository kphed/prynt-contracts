// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV3Pool {
    function tickSpacing() external view returns (int24);
}
