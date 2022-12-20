// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

/// @title EIP-5313 Light Contract Ownership Standard
interface EIP5313LightweightOwner {
    /// @notice Get the address of the owner
    /// @return The address of the owner
    function owner() view external returns(address);
}
