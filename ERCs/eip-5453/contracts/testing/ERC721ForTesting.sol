// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract ERC721ForTesting is ERC721 {

    constructor() ERC721("ERC721ForTesting", "ERC721ForTesting") {}
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
    }

}
