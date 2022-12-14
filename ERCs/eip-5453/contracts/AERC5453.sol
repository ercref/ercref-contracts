// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

struct SingleEndorsementData {
    address endorserAddress; // 32
    bytes sig;               // dynamic = 65
                             // SUM: 161
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
}
