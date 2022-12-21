// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721ForTesting is ERC721 {
    constructor() ERC721("ERC721ForTesting", "ERC721ForTesting") {}
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId, bytes calldata data) public {
        _safeMint(to, tokenId, data);
    }

    function batchMint(address[] calldata tos, uint256[] calldata tokenIds) external {
        require(tos.length == tokenIds.length, "ERC721ForTesting: tos and tokenIds length mismatch");
        for (uint256 i = 0; i < tos.length; ++i) {
            _mint(tos[i], tokenIds[i]);
        }
    }

    function batchSafeMint(address[] calldata tos, uint256[] calldata tokenIds) external {
        require(tos.length == tokenIds.length, "ERC721ForTesting: tos and tokenIds length mismatch");
        for (uint256 i = 0; i < tos.length; ++i) {
            _safeMint(tos[i], tokenIds[i]);
        }
    }
}
