// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

struct SingleEndorsementData {
    address endorserAddress; // 32
    bytes sig;               // dynamic = 65
}

struct GeneralExtensonData {
    bytes32 magicWord;
    uint256 verson;
    uint256 nonce;
    uint256 validSince;
    uint256 validBy;
    bytes payload;
}

abstract contract AERC5453Endorsible {
    uint256 private threshold;

    uint256 currentNonce = 0;
    bytes32 constant MAGIC_WORLD = keccak256("ENDORSEMENT"); // ASCII of "ENDORSED"
    uint256 constant VERSION_SINGLE = 1;
    uint256 constant VERSION_MULTIPLE = 2;

    function _validate(bytes32 msgDigest, SingleEndorsementData memory endersement) internal virtual {
            require(SignatureChecker.isValidSignatureNow(endersement.endorserAddress, msgDigest, endersement.sig));
    }
    function _extractEndorsers(bytes32 digest, GeneralExtensonData memory data) internal virtual returns (address[] memory endorsers) {
        require(data.magicWord == MAGIC_WORLD);
        require(data.validSince <= block.timestamp);
        require(data.validBy >= block.timestamp);
        require(currentNonce == data.nonce);
        currentNonce += 1;

        if (data.verson == VERSION_SINGLE) {
            SingleEndorsementData memory endersement = abi.decode(data.payload, (SingleEndorsementData));
            endorsers = new address[](1);
            endorsers[0] = endersement.endorserAddress;
            _validate(digest, endersement);
        } else if (data.verson == VERSION_MULTIPLE) {
            SingleEndorsementData[] memory endorsements = abi.decode(data.payload, (SingleEndorsementData[]));
            endorsers = new address[](endorsements.length);
            for (uint256 i = 0; i < endorsements.length; ++i) {
                endorsers[i] = endorsements[i].endorserAddress;
                _validate(digest, endorsements[i]);
            }
            return endorsers;
        }
    }
    function _extractExtension(bytes memory extraData) internal virtual returns (GeneralExtensonData memory) {
        return abi.decode(extraData, (GeneralExtensonData));
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

    function _isEndorsed(bytes memory _methodName, bytes32 _dataDigest, bytes calldata _extraData) internal returns (bool) {
        GeneralExtensonData memory _data = _extractExtension(_extraData);
        bytes memory dataWithValidityBound = abi.encodePacked(_dataDigest, _data.validSince, _data.validBy, _data.nonce);
        // TODO better packing for EIP712
        bytes32 finalDigest = _computeDigest(_methodName, dataWithValidityBound);
        address[] memory endorsers = _extractEndorsers(finalDigest, _data);
        require(endorsers.length >= threshold);
        require(_noRepeat(endorsers));
        for (uint256 i = 0; i < endorsers.length; i++) {
            require(_isEligibleEndorser(endorsers[i])); // everyone is a legit endorser
        }
        return true;
    }

    function _isEligibleEndorser(address _endorser) internal virtual view returns (bool) {return false;}

    modifier onlyEndorsed(bytes memory _methodName, bytes32 _dataDigest, bytes calldata _extraData) {
        require(_isEndorsed(_methodName, _dataDigest, _extraData));
        _;
    }


    function _eip712DomainTypeHash() internal pure returns (bytes32) {
        return
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            );
    }

    function _eip712DomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _eip712DomainTypeHash(),
                    keccak256(bytes("DoubleGuardianForwarder")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    function eip712DomainSeparator() external view returns (bytes32) {
        return _eip712DomainSeparator();
    }

    function _computeDigest(
        bytes memory _name,
        bytes memory _dataWithValidityBound
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _eip712DomainSeparator(),
                    keccak256(
                        abi.encode(
                            keccak256(_name),
                            _dataWithValidityBound
                        )
                    )
                )
            );
    }

    function setThreshold(uint256 _threshold) internal {
        threshold = _threshold;
    }
}
