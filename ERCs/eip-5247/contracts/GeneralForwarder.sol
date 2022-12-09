// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC5247.sol";
import "@openzeppelin/contracts/utils/Address.sol";

struct Proposal {
    address by;
    uint256 proposalId;
    address[] targets;
    uint256[] values;
    uint256[] gasLimits;
    bytes[] calldatas;
}

contract GeneralForwarder
{
    using Address for address;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    function createProposal(
        address by,
        uint256 proposalId,
        address[] calldata targets,
        uint256[] calldata values,
        uint256[] calldata gasLimits,
        bytes[] calldata calldatas
    ) external returns (uint256 registeredProposalId) {
        require(targets.length == values.length, "GeneralForwarder: targets and values length mismatch");
        require(targets.length == gasLimits.length, "GeneralForwarder: targets and gasLimits length mismatch");
        require(targets.length == calldatas.length, "GeneralForwarder: targets and calldatas length mismatch");
        registeredProposalId = proposalCount;

        proposals[registeredProposalId] = Proposal({
            by: by,
            proposalId: proposalId,
            targets: targets,
            values: values,
            calldatas: calldatas,
            gasLimits: gasLimits
        });
        proposalCount++;
        return registeredProposalId;
    }

    function execute(uint256 proposalId, bytes calldata extraParams) external {
        Proposal storage proposal = proposals[proposalId];
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < proposal.targets.length; ++i) {
            (bool success, bytes memory returndata) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }
}
