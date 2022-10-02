// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// Open source repo: http://zzn.li/ercref

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC5679.sol";

contract ERC5679Ext721RefImpl is ERC5679Ext721, ERC721 {

    event ErcRefImplDeploy(uint256 version, string name, string url);
    constructor(uint256 _version)
        ERC721("ERC5679Ext721RefImpl", "ERC5679Ext721RefImpl")
    {
        emit ErcRefImplDeploy(_version, "ERC5679Ext721RefImpl", "http://zzn.li/ercref");
    }

    function safeMint(
        address _to,
        uint256 _id,
        bytes calldata // _data (unused)
    ) external override {
        // NO ACCESS CONTROL in this simple reference implementation.
        // Please DO NOT USE this in production.
        _safeMint(_to, _id); // ignoring _data in this simple reference implementation.
    }

    function burn(
        address, // _from, (unused)
        uint256 _id,
        bytes calldata // _data (unused)
    ) external override {
        // NO ACCESS CONTROL in this simple reference implementation.
        // Please DO NOT USE this in production.
        _burn(_id); // ignoring _data in this simple reference implementation.
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC5679Ext721, ERC721)
        returns (bool)
    {}


}
