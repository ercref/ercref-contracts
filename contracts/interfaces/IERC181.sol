// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

interface IERC181ENSRegistrar {
    function claim(address owner) external returns (bytes32 node);
    function claimWithResolver(address owner, address resolver) external returns (bytes32 node);
    function setName(string calldata name) external returns (bytes32 node);
}

interface IERC181ENSReverseResolver {
    function name(bytes32 node) external view returns (string memory);
}
