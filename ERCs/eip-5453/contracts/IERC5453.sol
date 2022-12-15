// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>

pragma solidity ^0.8.9;

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

interface IERC5453EndorsementCore {
    function getCurrentNonce(address endorser) external view returns (uint256);
}

interface IERC5453EndorsementHelper {
    function computeValidityDigest(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) external view returns (bytes32);

    function computeFunctionParamHash(
        string memory _functionName,
        bytes memory _functionParamPacked
    ) external view returns (bytes32);

    function computeExtensionDataTypeA(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address endorserAddress,
        bytes calldata sig
    ) external view returns (bytes memory);

    function computeExtensionDataTypeB(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address[] calldata endorserAddress,
        bytes[] calldata sigs
    ) external view returns (bytes memory);
}