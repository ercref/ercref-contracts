// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20TokenWithFee is ERC20 {
    uint256 private _feeRatePer10000 = 0;
    address private _feeReceiver = address(0);

    constructor(

    ) ERC20("ERC20TokenWithFee", "ERC20TWF") {
        _feeRatePer10000 = 1000;
        _feeReceiver = msg.sender;
    }

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function feeAmount(address from, address to, uint256 transferBaseAmount) public view virtual returns(uint256) {
        return _feeAmount(from, to, transferBaseAmount);
    }

    function _feeAmount(address from, address to, uint256 transferBaseAmount) internal view virtual returns(uint256) {
        // TODO: use Math.sol to avoid overflow
        return transferBaseAmount * _feeRatePer10000 / 10000;
    }

    function _transferWithFee(address from, address to, uint256 amount) internal virtual {
        uint256 feeAmount = _feeAmount(from, to, amount);
        uint256 receivedAmount = amount - feeAmount;
        _transfer(from, _feeReceiver, feeAmount);
        _transfer(from, to, receivedAmount);

    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithFee(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithFee(sender, recipient, amount);
        return true;
    }
}
