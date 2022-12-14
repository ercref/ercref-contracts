// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./AERC5453.sol";

contract ERC721Endorsible is ERC721, AERC5453Endorsible, Ownable {

    constructor() ERC721("ERC721ForTesting", "ERC721ForTesting") Ownable() {

    }

    function mint(address _to, uint256 _tokenId, bytes calldata _extraData)
    onlyEndorsed(
        bytes("mint(address _to,uint256 _tokenId,bytes calldata _extraData)"),
        keccak256(abi.encodePacked(_to, _tokenId)),
        _extraData)
    external {
        _mint(_to, _tokenId);
    }

    function _isEligibleEndorser(address _endorser) internal view override returns (bool) {
        return true;
    }
}
