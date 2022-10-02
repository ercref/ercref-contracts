// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC5679.sol";

contract ERC5679Ext20RefImpl is ERC5679Ext20, ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(
        address _to,
        uint256 _amount,
        bytes[] calldata // _data (unused)
    ) external override {
        _mint(_to, _amount); // ignoring _data in this simple reference implementation.
    }

    function burn(
        address _from,
        uint256 _amount,
        bytes[] calldata // _data (unused)
    ) external override {
        _burn(_from, _amount); // ignoring _data in this simple reference implementation.
    }
}
