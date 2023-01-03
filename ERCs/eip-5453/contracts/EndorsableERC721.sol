// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./AERC5453.sol";

contract EndorsableERC721 is ERC721, AERC5453Endorsible {
    mapping(address => bool) private owners;

    constructor()
        ERC721("ERC721ForTesting", "ERC721ForTesting")
        AERC5453Endorsible("EndorsableERC721", "v1")
    {
        owners[msg.sender] = true;
    }

    function addOwner(address _owner) external {
        require(owners[msg.sender], "EndorsableERC721: not owner");
        owners[_owner] = true;
    }

    function mint(
        address _to,
        uint256 _tokenId,
        bytes calldata _extraData
    )
        external
        onlyEndorsed(
            _computeFunctionParamHash(
                "function mint(address _to,uint256 _tokenId)",
                abi.encode(_to, _tokenId)
            ),
            _extraData
        )
    {
        _mint(_to, _tokenId);
    }

    function _isEligibleEndorser(
        address _endorser
    ) internal view override returns (bool) {
        return owners[_endorser];
    }

    function decodeExtensionData(
        bytes memory extensionData
    ) external pure returns (GeneralExtensionDataStruct memory) {
        return super._decodeExtensionData(extensionData);
    }

    function decodeSingleEndorsementData(bytes calldata payload)
        external pure returns(SingleEndorsementData memory endersement) {
        return abi.decode(
                payload,
                (SingleEndorsementData)
            );
    }

    function extractEndorsers(
        bytes32 _functionParamStructHash,
        bytes calldata _extraData
    ) external view returns(
        address[] memory _endorsers,
        bytes32 _finalDigest,
        GeneralExtensionDataStruct memory _structureData) {
        return super._extractEndorsers(_functionParamStructHash, _extraData);
    }

    function isValidSignatureNow(
        address _claimedSigner,
        bytes32 _digest,
        bytes calldata _sig
    ) external view returns (bool) {
        return SignatureChecker.isValidSignatureNow(
                _claimedSigner,
                _digest,
                _sig
        );
    }
}
