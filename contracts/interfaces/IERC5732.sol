// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

// The EIP-165 identifier of this interface is 0xf14fcbc8
interface IERC5732CommitCore {
    function commit(bytes32 _commitment) payable external;
}

// The EIP-165 identifier of this interface is 0x67b2ec2c
interface IERC5732CommitGeneral {
    event Commit(
        uint256 indexed _timePoint,
        address indexed _from,
        bytes32 indexed _commitment,
        bytes _extraData);
    function commitFrom(
        address _from,
        bytes32 _commitment,
        bytes calldata _extraData)
    payable external returns(uint256 timePoint);
}
