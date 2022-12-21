// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

interface IERC1271Signature {
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}
