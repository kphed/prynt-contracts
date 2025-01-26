// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solady/tokens/ERC20.sol";

contract PryntERC20 is ERC20 {
    string private _name;
    string private _symbol;

    /// @notice Timestamp of when the round will end.
    uint256 public immutable roundEnd;

    /// @notice Address of the round leader.
    address public roundLeader;

    event NewLeader(address leader);

    constructor(string memory name_, string memory symbol_, uint256 roundEnd_) {
        _name = name_;
        _symbol = symbol_;
        roundEnd = roundEnd_;
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
            block.timestamp < roundEnd && balanceOf(to) > balanceOf(roundLeader)
        ) {
            roundLeader = to;

            emit NewLeader(to);
        }
    }
}
