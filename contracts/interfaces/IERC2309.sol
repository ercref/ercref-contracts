pragma solidity ^0.8.9;

interface IERC2309ERC721Receiver {
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}
