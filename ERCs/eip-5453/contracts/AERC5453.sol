// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

struct ValidityBound {
    bytes32 functionParamStructHash;
    uint256 validSince;
    uint256 validBy;
    uint256 nonce;
}

struct SingleEndorsementData {
    address endorserAddress; // 32
    bytes sig; // dynamic = 65
}

struct GeneralExtensonDataStruct {
    bytes32 magicWord;
    uint256 verson;
    uint256 nonce;
    uint256 validSince;
    uint256 validBy;
    bytes payload;
}

abstract contract AERC5453Endorsible is EIP712 {
    uint256 private threshold;

    uint256 currentNonce = 0;
    bytes32 constant MAGIC_WORLD = keccak256("ENDORSEMENT"); // ASCII of "ENDORSED"
    uint256 constant VERSION_SINGLE = 1;
    uint256 constant VERSION_MULTIPLE = 2;

    constructor(
        string memory _name,
        string memory _version
    ) EIP712(_name, _version) {}

    function _validate(
        bytes32 msgDigest,
        SingleEndorsementData memory endersement
    ) internal virtual {
        require(
            SignatureChecker.isValidSignatureNow(
                endersement.endorserAddress,
                msgDigest,
                endersement.sig
            )
        );
    }

    function _extractEndorsers(
        bytes32 digest,
        GeneralExtensonDataStruct memory data
    ) internal virtual returns (address[] memory endorsers) {
        require(data.magicWord == MAGIC_WORLD);
        require(data.validSince <= block.timestamp);
        require(data.validBy >= block.timestamp);
        require(currentNonce == data.nonce);
        currentNonce += 1;

        if (data.verson == VERSION_SINGLE) {
            SingleEndorsementData memory endersement = abi.decode(
                data.payload,
                (SingleEndorsementData)
            );
            endorsers = new address[](1);
            endorsers[0] = endersement.endorserAddress;
            _validate(digest, endersement);
        } else if (data.verson == VERSION_MULTIPLE) {
            SingleEndorsementData[] memory endorsements = abi.decode(
                data.payload,
                (SingleEndorsementData[])
            );
            endorsers = new address[](endorsements.length);
            for (uint256 i = 0; i < endorsements.length; ++i) {
                endorsers[i] = endorsements[i].endorserAddress;
                _validate(digest, endorsements[i]);
            }
            return endorsers;
        }
    }

    function _extractExtension(
        bytes memory extensionData
    ) internal virtual returns (GeneralExtensonDataStruct memory) {
        return abi.decode(extensionData, (GeneralExtensonDataStruct));
    }

    // Well, I know this is epensive. Let's improve it later.
    function _noRepeat(address[] memory _owners) internal pure returns (bool) {
        for (uint256 i = 0; i < _owners.length; i++) {
            for (uint256 j = i + 1; j < _owners.length; j++) {
                if (_owners[i] == _owners[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function _isEndorsed(
        bytes32 _functionParamStructHash,
        bytes calldata _extraData
    ) internal returns (bool) {
        GeneralExtensonDataStruct memory _data = _extractExtension(_extraData);

        bytes32 finalDigest = _computeDigestWithBound(
            _functionParamStructHash,
            _data.validSince,
            _data.validBy,
            _data.nonce
        );

        address[] memory endorsers = _extractEndorsers(finalDigest, _data);
        require(endorsers.length >= threshold);
        require(_noRepeat(endorsers));
        for (uint256 i = 0; i < endorsers.length; i++) {
            require(_isEligibleEndorser(endorsers[i])); // everyone is a legit endorser
        }
        return true;
    }

    function _isEligibleEndorser(
        address _endorser
    ) internal view virtual returns (bool) {
        return false;
    }

    modifier onlyEndorsed(
        bytes32 _functionParamStructHash,
        bytes calldata _extensionData
    ) {
        require(_isEndorsed(_functionParamStructHash, _extensionData));
        _;
    }

    function _computeDigestWithBound(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) internal view returns (bytes32) {
        return
            super._hashTypedDataV4(
                keccak256(
                    abi.encode(keccak256("ValidityBound(bytes32 _functionParamStructHash,uint256 validSince,uint256 validBy,uint256 nonce)"),
                    _functionParamStructHash,
                    _validSince,
                    _validBy,
                    _nonce
                ))
            );
    }

    function _computeFunctionParamStructHash(
        string memory _functionName,
        bytes memory _functionParamPacked) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(bytes(_functionName)), _functionParamPacked));
    }



    function _setThreshold(uint256 _threshold) internal virtual {
        threshold = _threshold;
    }

    function computeDigestWithBound(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) external view returns (bytes32) {
        return _computeDigestWithBound(_functionParamStructHash, _validSince, _validBy, _nonce);
    }

    function computeFunctionParamStructHash(
        string memory _functionName,
        bytes memory _functionParamPacked) external pure returns (bytes32) {
        return _computeFunctionParamStructHash(_functionName, _functionParamPacked);
    }
}
