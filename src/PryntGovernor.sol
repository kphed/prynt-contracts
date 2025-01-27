// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorStorage} from "@openzeppelin/contracts/governance/extensions/GovernorStorage.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract PryntGovernor is
    GovernorStorage,
    GovernorSettings,
    GovernorVotesQuorumFraction,
    GovernorCountingSimple,
    GovernorTimelockControl
{
    string private constant _NAME = "Prynt DAO Governor";

    constructor(
        Votes prynt,
        TimelockController timelockController,
        uint48 initialVotingDelay,
        uint32 initialVotingPeriod,
        uint256 initialProposalThreshold,
        uint256 initialQuorumNumerator
    )
        Governor(_NAME)
        GovernorSettings(
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold
        )
        GovernorVotes(prynt)
        GovernorVotesQuorumFraction(initialQuorumNumerator)
        GovernorTimelockControl(timelockController)
    {}

    /**
     * @notice The number of votes required in order for a voter to become a proposer.
     */
    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return GovernorSettings.proposalThreshold();
    }

    /**
     * @notice Creates a proposal and stores the details.
     * @param  targets      address[]  List of contracts to be called.
     * @param  values       uint256[]  List of values attached to each call.
     * @param  calldatas    bytes[]    List of contract calldata.
     * @param  description  string     Proposal description.
     * @param  proposer     address    Proposer.
     * @return proposalId   uint256    Proposal id.
     */
    function _propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        address proposer
    )
        internal
        override(Governor, GovernorStorage)
        returns (uint256 proposalId)
    {
        return
            GovernorStorage._propose(
                targets,
                values,
                calldatas,
                description,
                proposer
            );
    }

    /**
     * @notice Allows a proposer to cancel their (queued) proposal.
     * @param  targets          address[]  List of contracts to be called.
     * @param  values           uint256[]  List of values attached to each call.
     * @param  calldatas        bytes[]    List of contract calldata.
     * @param  descriptionHash  bytes32    Keccak256 hash of the proposal description.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return
            GovernorTimelockControl._cancel(
                targets,
                values,
                calldatas,
                descriptionHash
            );
    }

    /**
     * @notice Runs a queued proposal through the timelock.
     * @param  proposalId       uint256    Proposal id.
     * @param  targets          address[]  List of contracts to be called.
     * @param  values           uint256[]  List of values attached to each call.
     * @param  calldatas        bytes[]    List of contract calldata.
     * @param  descriptionHash  bytes32    Keccak256 hash of the proposal description.
     */
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        return
            GovernorTimelockControl._executeOperations(
                proposalId,
                targets,
                values,
                calldatas,
                descriptionHash
            );
    }

    /**
     * @notice Address through which the governor executes action.
     */
    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return GovernorTimelockControl._executor();
    }

    /**
     * @notice Queue a proposal for execution.
     * @param  proposalId       uint256    Proposal id.
     * @param  targets          address[]  List of contracts to be called.
     * @param  values           uint256[]  List of values attached to each call.
     * @param  calldatas        bytes[]    List of contract calldata.
     * @param  descriptionHash  bytes32    Keccak256 hash of the proposal description.
     */
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return
            GovernorTimelockControl._queueOperations(
                proposalId,
                targets,
                values,
                calldatas,
                descriptionHash
            );
    }

    /**
     * @notice Whether a proposal needs to be queued.
     * @param  proposalId  uint256  Proposal id.
     */
    function proposalNeedsQueuing(
        uint256 proposalId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        ProposalState proposalState = GovernorTimelockControl.state(proposalId);

        return proposalState == ProposalState.Succeeded;
    }

    /**
     * @notice The state of a proposal with consideration for the timelock.
     * @param  proposalId  uint256  Proposal id.
     */
    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return GovernorTimelockControl.state(proposalId);
    }
}
