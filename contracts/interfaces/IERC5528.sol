pragma solidity ^0.4.20;

interface IERC5528RefundableFungibleToken {

    function escrowFund(address _to, uint256 _value) public returns (bool);

    function escrowRefund(address _from, uint256 _value) public returns (bool);

    function escrowWithdraw() public returns (bool);

}
