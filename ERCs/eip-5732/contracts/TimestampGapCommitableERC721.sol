// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// Visit our open source repo: http://zzn.li/ercref

pragma solidity ^0.8.17;

import "./IERC5732.sol";
import "./TimestampGapCommit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @dev Implementation of the {IERC_COMMIT} interface for the Mint use case.
/// Assuming "TokenID" represents something intersting that people want to
/// run to mint for. This reference implementation breakdown the minting
/// process into two steps:
/// Step1. One user calls the `commit` inorder to commit to a minting request
///     but the actual `tokenId` is not yet revealed to general public.
/// Step2. After sometime, that same user calls the "mint" with the actual
///     `tokenId` to mint the token, which reveals the token.
///     The mint request also contains the a `secret_sault` in its ExtraData.
contract TimestampGapCommitableERC721 is ERC721, TimestampGapCommit {
    uint256 constant MANDATORY_TIMESTAMP_GAP = 60;
    constructor()
        ERC721("TimestampGapCommitableERC721", "TGCTMI")
        AERCRef("TimestampGapCommitableERC721", 2) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, TimestampGapCommit)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function safeMint(
        address _to,
        uint256 _tokenId,
        bytes calldata _extraData
    )   onlyCommited(
            abi.encodePacked(_to, _tokenId),
            bytes32(_extraData[0:32]), // The first 32bytes of safeMint._extraData is being used as salt
            MANDATORY_TIMESTAMP_GAP
        )
        external {
        _safeMint(_to, _tokenId); // ignoring _extraData in this simple reference implementation.
    }

    function get165Core() external pure returns (bytes4) {
        return type(IERC_COMMIT_CORE).interfaceId;
    }

    function get165General() external pure returns (bytes4) {
        return type(IERC_COMMIT_GENERAL).interfaceId;
    }
}
