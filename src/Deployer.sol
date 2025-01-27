// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {PryntGovernor} from "src/PryntGovernor.sol";
import {Prynt} from "src/Prynt.sol";

contract Deployer {
    /// @notice Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol#L25.
    bytes32 private constant _TIMELOCK_PROPOSER_ROLE =
        keccak256("PROPOSER_ROLE");
    bytes32 private constant _TIMELOCK_EXECUTOR_ROLE =
        keccak256("EXECUTOR_ROLE");
    bytes32 private constant _TIMELOCK_CANCELLER_ROLE =
        keccak256("CANCELLER_ROLE");

    /// @notice Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol#L57.
    bytes32 private constant _TIMELOCK_ADMIN_ROLE = 0x00;

    TimelockController public immutable timelock;
    PryntGovernor public immutable governor;
    Prynt public immutable prynt;

    constructor(
        address registry,
        address uniswapPositionManager,
        uint256 roundDuration,
        uint256 timelockMinDelay,
        uint48 _votingDelay,
        uint32 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumNumerator,
        address guardianMultisig
    ) {
        timelock = new TimelockController(
            timelockMinDelay,
            new address[](0),
            new address[](0),
            address(this)
        );
        prynt = new Prynt(
            registry,
            address(timelock),
            uniswapPositionManager,
            roundDuration
        );
        governor = new PryntGovernor(
            prynt,
            timelock,
            _votingDelay,
            _votingPeriod,
            _proposalThreshold,
            _quorumNumerator
        );

        // Governor has the power to propose, cancel, and execute timelock transactions.
        timelock.grantRole(_TIMELOCK_PROPOSER_ROLE, address(governor));
        timelock.grantRole(_TIMELOCK_EXECUTOR_ROLE, address(governor));
        timelock.grantRole(_TIMELOCK_CANCELLER_ROLE, address(governor));

        // The guardian multisig, made up of DAO-approved signers, has the power to cancel proposals it deems malicious.
        timelock.grantRole(_TIMELOCK_CANCELLER_ROLE, guardianMultisig);

        // Future role assignments will be performed by token holders via onchain governance.
        timelock.renounceRole(_TIMELOCK_ADMIN_ROLE, address(this));
    }
}
