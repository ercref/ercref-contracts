// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IERC5298 {
    function claimTo(
        address to,
        bytes32 ensNode,
        address operator,
        uint256 tokenId
    ) payable external;
}
