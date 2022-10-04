// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/SignatureChecker.sol";
import "./IERC5453.sol";

struct EndorsementType1 {
    endorserAddress: address;
    endorserNounce: uint256;
    validSince: uint256;
    validBy: uint256;
    r: bytes32;
    s: bytes32;
    v: bytes1;
    formatType: bytes2;
    magicWorld: bytes8;
}

abstract contract AERC5453 is IERC5453 {
    mapping(address => uint256) endorserNounces;
    const uint256 LENGTH_OF_ENDORSEMENT = 193;
    const byte8 MAGIC_WORLD = 0x5453454e4f524445; // "ENDORSED"
    const byte2 FIRST_TYPE_SINGLE_ENDORSER = 0x0001;
    // TODO this is not completed yet.
    function onlyEndorsed(uint256 _eligibilityIdentifier, bytes32 _msgDigest, bytes calldata _e/**Enorsement**/) returns (address) {
        require(_e.length == LENGTH_OF_ENDORSEMENT);
        require(_e[_e.length - 8:] == MAGIC_WORLD);
        byte2 erc5453FormatType = _e[_e.length - 10:_e.length - 8];
        if (erc5453FormatType == FIRST_TYPE_SINGLE_ENDORSER) {
            EndorsementType1 memory sE/*structured endorsement*/ = abi.decode(_e, (EndorsementType1));
            require(block.number >= sE.validSince && block.number < sE.validBy, "Endorsement is not valid at this time");
            require(sE.endorserNounce == _endorserNounce[sE.endorserAddress], "Endorsement is not valid at this time");
            _endorserNounce[sE.endorserAddress] += 1;
            SignatureChecker.isValidSignatureNow(sE.endorserAddress, _msgDigest, abi.encodePacked(sE.r, sE.s, sE.v));
        } else {
            revert("Unsupported endorsement format");
        }
        require(_isEligibleEndorser(_eligibilityIdentifier, sE.endorserAddress), "Endorser is not eligible");
        _;
    }
}
