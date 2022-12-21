// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

interface IERC1967Logical {
    event Upgraded(address indexed implementation);
}

interface IERC1967Beacon {
    event BeaconUpgraded(address indexed beacon);
    function implementation() external returns (address);
}

interface IERC1967Admin {
    event AdminChanged(address previousAdmin, address newAdmin);
}
