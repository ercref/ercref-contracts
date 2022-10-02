// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// Open source repo: http://zzn.li/ercref

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC5679.sol";

contract ERC5679Ext20RefImpl is ERC5679Ext20, ERC20 {
    event ErcRefImplDeploy(uint256 version, string name, string url);
    constructor(uint256 _version) ERC20("ERC5679Ext20RefImpl", "ERC5679Ext20RefImpl") {
        emit ErcRefImplDeploy(_version, "ERC5679Ext20RefImpl", "http://zzn.li/ercref");
    }

    function mint(
        address _to,
        uint256 _amount,
        bytes calldata // _data (unused)
    ) external override {
        // EVERYONE can mint tokens in this simple reference implementation.
        // Please DO NOT USE this in production.
        _mint(_to, _amount); // ignoring _data in this simple reference implementation.
    }

    function burn(
        address _from,
        uint256 _amount,
        bytes calldata // _data (unused)
    ) external override {
        // EVERYONE can burn tokens in this simple reference implementation.
        // Please DO NOT USE this in production.
        _burn(_from, _amount); // ignoring _data in this simple reference implementation.
    }
}
