// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// Visit our open source repo: http://zzn.li/ercref

pragma solidity ^0.8.17;

import "./IERC5732.sol";
import "./utils/AERCRef.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @dev Implementation of the {IERC_COMMIT} interface for the Mint use case.
/// Assuming "TokenID" represents something intersting that people want to
/// run to mint for. This reference implementation breakdown the minting
/// process into two steps:
/// Step1. One user calls the `commit` inorder to commit to a minting request
///     but the actual `tokenId` is not yet revealed to general public.
/// Step2. After sometime, that same user calls the "mint" with the actual
///     `tokenId` to mint the token, which reveals the token.
///     The mint request also contains the a `secret_sault` in its ExtraData.
abstract contract TimestampGapCommit is AERCRef, IERC_COMMIT_CORE, IERC_COMMIT_GENERAL, ERC165 {
    mapping(address => bytes32) private commitments;
    mapping(address => uint256) private commitTimes;

    function supportsInterface(bytes4 interfaceId)
        public
        override
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC_COMMIT_CORE).interfaceId ||
            interfaceId == type(IERC_COMMIT_GENERAL).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function commit(bytes32 _commitment) override payable external virtual  {
        _commitFrom(msg.sender, _commitment, "");
    }

    function commitFrom(
        address _from,
        bytes32 _commitment,
        bytes calldata _extraData
    ) override payable external virtual returns(uint256)  {
        require(_from == msg.sender, "Sender must be commiter in this one.");
        return _commitFrom(_from, _commitment, _extraData);
    }

    function _commitFrom(
        address _from,
        bytes32 _commitment,
        bytes memory _extraData
    ) internal virtual returns(uint256)  {
        // For simplicity, it's ok to update commitment if it's already set.
        commitments[msg.sender] = _commitment;
        uint256 timestamp = block.timestamp;
        commitTimes[msg.sender] = timestamp;
        emit Commit(timestamp, _from, _commitment, _extraData);
        return timestamp;
    }

    function calculateCommitment(
        address _to,
        uint256 _tokenId,
        bytes32 salt
    ) external virtual pure returns(bytes32) {
        return keccak256(abi.encodePacked(_to, _tokenId, salt));
    }

    function _reveal(
        bytes memory _dataToSeal,
        bytes32 _salt,
        uint256 gap // timestamp gap in seconds
    ) internal virtual returns(bool) {
        require(
            commitments[msg.sender] == keccak256(abi.encodePacked(_dataToSeal, _salt)),
            "TimestampGapCommit: Invalid commitment"
        );

        require(
            block.timestamp >= commitTimes[msg.sender] + gap,
            "TimestampGapCommit: Not enough commitment timestamp gap yet."
        );
        // For simplicity, it's ok to mint to anyone.
        // Please DO NOT USE this in production.
        delete commitments[msg.sender];
        delete commitTimes[msg.sender];
        return true;
    }

    /// @dev A modifier for reveal function
    /// @param _dataToSeal The data to seal in the commitments
    /// @param _salt The salt to seal in the commitments
    /// @param _gap The timestamp gap to wait before minting.
    modifier onlyCommited(
        bytes memory _dataToSeal,
        bytes32 _salt,
        uint256 _gap) {
        require(_reveal(_dataToSeal, _salt, _gap), "TimestampGapCommit: Not commited or invalid commitment.");
        _;
    }
}
