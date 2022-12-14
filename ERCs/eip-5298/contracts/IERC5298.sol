// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IERC5298_CORE {
    function claimTo(
        address to,
        bytes32 ensNode,
        address operator,
        uint256 tokenId
    ) payable external;
}

interface IERC5298_GENERAL {
    event AddedToHolding(bytes32 indexed ensNode, address indexed operator, uint256 indexed tokenId);
    event RemovedFromHolding(bytes32 indexed ensNode, address indexed operator, uint256 indexed tokenId);
    function addToHolding(bytes32 ensNode, address tokenContractAddress, uint256 tokenId) external payable;
    function removeFromHolding(bytes32 ensNode, address tokenContractAddress, uint256 tokenId) external payable;
}
