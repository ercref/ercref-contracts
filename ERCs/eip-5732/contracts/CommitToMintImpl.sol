// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// Visit our open source repo: http://zzn.li/ercref

pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./IERC5732.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Implementation of the {IERC_COMMIT} interface for the Mint use case.
 * Assuming "TokenID" represents something intersting that people want to
 * run to mint for. This reference implementation breakdown the minting
 * process into two steps:
 *  Step1. One user calls the `commit` inorder to commit to a minting request
 *        but the actual `tokenId` is not yet revealed to general public.
 *  Step2. After sometime, that same user calls the "mint" with the actual
 *        `tokenId` to mint the token, which reveals the token.
 *        The mint request also contains the a `secret_sault` in its ExtraData.
 */
contract CommitToMintImpl is ERC721, IERC_COMMIT  {
    mapping(address => bytes32) public commitToMint;
    event ErcRefImplDeploy(uint256 version, string name, string url);
    constructor(uint256 _version) ERC721("CommitToMintImpl", "CTMI") {
        emit ErcRefImplDeploy(_version, "CommitToMintImpl", "http://zzn.li/ercref");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC_COMMIT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function commit(bytes32 _commitment, bytes calldata _extraData) payable public  {
        // For simplicity, it's ok to update commitment if it's already set.
        commitToMint[msg.sender] = _commitment;
        emit Commit(_commitment, _extraData);
    }

    function calculateCommitment(
        address _to,
        uint256 _tokenId,
        bytes calldata _extraData
    ) public pure returns(bytes32) {
        bytes32 salt = bytes32(_extraData[0:32]);
        return keccak256(abi.encodePacked(_to, _tokenId, salt));
    }
    function safeMint(
        address _to,
        uint256 _tokenId,
        bytes calldata _extraData
    ) external {
        require(_extraData.length == 32, "The extraData shall be 32 bytes");
        bytes32 salt = bytes32(_extraData[0:32]);
        require(
            commitToMint[msg.sender] == keccak256(abi.encodePacked(_to, _tokenId, salt)),
            "CommitToMintImpl: Invalid commitment"
        );
        // For simplicity, it's ok to mint to anyone.
        // Please DO NOT USE this in production.
        delete commitToMint[msg.sender];
        _safeMint(_to, _tokenId); // ignoring _extraData in this simple reference implementation.
    }

    function get165() public pure returns (bytes4) {
        return type(IERC_COMMIT).interfaceId;
    }
}
