// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

// Minimal interface to ERC20 token.
interface IERC20TokenCore {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256 balance);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool success);
    function transfer(address recipient, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// Optional functions from the ERC20 standard.
interface IERC20TokenMetadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
