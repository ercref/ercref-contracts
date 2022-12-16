// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

interface IERC5528RefundableFungibleToken {

    function escrowFund(address _to, uint256 _value) external returns (bool);

    function escrowRefund(address _from, uint256 _value) external returns (bool);

    function escrowWithdraw() external returns (bool);

}
