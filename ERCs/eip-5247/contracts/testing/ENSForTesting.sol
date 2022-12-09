// SPDX-License-Identifier: UNLICENSED
// ALL CODE HERE IS FOR A HACKATHON AND IS NOT MEANT TO BE USED IN PRODUCTION

pragma solidity ^0.8.9;
// Registry
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract ENSForTesting is ENS, Ownable {
    mapping(bytes32 => address) public nodeToOwner;
    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external {
        revert("Not implemented");
    }

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external {
        revert("Not implemented");
    }

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32) {
        revert("Not implemented");
    }

    function setResolver(bytes32 node, address resolver) external {
        revert("Not implemented");
    }

    function setOwner(bytes32 node, address ensNodeOwner) external onlyOwner {
        nodeToOwner[node] = ensNodeOwner;
    }

    function setTTL(bytes32 node, uint64 ttl) external {
        revert("Not implemented");
    }

    function setApprovalForAll(address operator, bool approved) external {
        revert("Not implemented");
    }

    function owner(bytes32 node) external view returns (address) {
        return nodeToOwner[node];
    }

    function resolver(bytes32 node) external view returns (address) {
        revert("Not implemented");
    }

    function ttl(bytes32 node) external view returns (uint64) {
        revert("Not implemented");
    }

    function recordExists(bytes32 node) external view returns (bool) {
        return true;
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool) {
            return true;
    }
}
