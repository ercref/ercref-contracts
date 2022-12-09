// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC5247 {
    event ProposalCreated(uint256 indexed proposalId, address indexed by);
    event ProposalExecuted(uint256 indexed proposalId, address indexed by);
    function createProposal(
        address by,
        uint256 proposalId,
        address[] calldata targets,
        uint256[] calldata values,
        uint256[] calldata gasLimits,
        bytes[] calldata calldatas
    ) external returns (uint256 registeredProposalId);
    function executeProposal(uint256 proposalId, bytes calldata extraParams) external;
}
