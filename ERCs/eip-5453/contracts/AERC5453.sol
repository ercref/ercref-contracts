// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/SignatureChecker.sol";
import "./IERC5453.sol";

struct SingleEndorsementData {
    endorserAddress: address; // 32
    endorserNounce: uint256;  // 32
    validSince: uint256;      // 32
    validBy: uint256;         // 32
    r: bytes32;               // 32
    s: bytes32;               // 32
    v: bytes1;                // 1
                              // SUM: 161
}

struct SingleEndorsement {
    SingleEndorsementData data;
    formatType: bytes2; // MUST be 0x0001
    magicWord: bytes8;
}

struct MultiEndorsement {
    SingleEndorsementData[] data;
    formatType: bytes2; // MUST be 0x0002
    magicWord: bytes8;
}

abstract contract Endorsible is IERC5453 {
    mapping(address => uint256) endorserNounces;
    bytes8 constant MAGIC_WORLD = 0x5453454e4f524445; // ASCII of "ENDORSED"
    bytes2 constant SINGLE_ENDORSER_TYPE = 0x0001;
    bytes2 constant MULTI_ENDORSER_TYPE = 0x0002;

    function _isEligibleEndorser(uint256 _eligibilityIdentifier, address _endorser) virtual internal;

    function _parseEndorser(
        uint256 _eligibilityIdentifier,
        bytes32 _msgDigest,
        bytes calldata _e // endorsemetn
    ) returns (address) {
        require(_e[_e.length - 8:] == MAGIC_WORLD);
        byte2 erc5453FormatType = _e[_e.length - 10:_e.length - 8];
        if (erc5453FormatType == SINGLE_ENDORSER_TYPE) {
            SingleEndorsement memory endorsement = abi.decode(_e[_e.length - SingleEndorsement.length:], (SingleEndorsement));
            require(endorsement.validSince <= block.number);
            require(endorsement.validBy >= block.number);
            require(endorsement.data.endorserNounce == endorserNounces[endorsement.data.endorserAddress]);
            endorserNounces[endorsement.data.endorserAddress] += 1;
            require(SignatureChecker.isValidSignatureNow(
                endorsement.data.endorserAddress,
                _msgDigest,
                abi.encodePacked(endorsement.data.r, endorsement.data.s, endorsement.data.v)
            ));
            return endorsement.data.endorserAddress;
        } else {
            revert("Unsupported endorsement format");
        }

    }
    modifier onlyEndorsed(
        uint256 _eligibilityIdentifier,
        bytes32 _msgDigest,
        bytes calldata _e // endorsement
    ) {
        address endorser = _parseEndorser(_eligibilityIdentifier, _msgDigest, _e);
        require(_isEligibleEndorser(_eligibilityIdentifier, endorser));
        _;
    }
}
