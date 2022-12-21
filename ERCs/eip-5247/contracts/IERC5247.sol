// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC5247 {
    event ProposalCreated(
        address indexed proposer,
        uint256 indexed proposalId,
        address[] targets,
        uint256[] values,
        uint256[] gasLimits,
        bytes[] calldatas,
        bytes extraParams
    );

    event ProposalExecuted(
        address indexed executor,
        uint256 indexed proposalId,
        bytes extraParams
    );

    function createProposal(
        uint256 proposalId,
        address[] calldata targets,
        uint256[] calldata values,
        uint256[] calldata gasLimits,
        bytes[] calldata calldatas,
        bytes calldata extraParams
    ) external returns (uint256 registeredProposalId);

    function executeProposal(uint256 proposalId, bytes calldata extraParams) external;
}
