// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
pragma solidity ^0.8.17;

import "./AERC5453.sol";

import "@openzeppelin/contracts/utils/Address.sol";

contract DoubleGuardianForwarder is AERC5453Endorsible {
    mapping(address => bool) private owners;
    uint256 private threshold;

    function computeDigest(
        address _dest,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _calldata
    ) external view returns (bytes32) {
        return _computeDigest(_dest, _value, _gasLimit, _calldata);
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
        address _dest,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _calldata
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _eip712DomainSeparator(),
                    keccak256(
                        abi.encode(
                            keccak256("forward(address,uint256,uint256,bytes)"),
                            _dest,
                            _value,
                            _gasLimit,
                            _calldata
                        )
                    )
                )
            );
    }

    function initialize(
        address[] calldata _owners,
        uint256 _threshold
    ) external {
        require(_owners.length >= _threshold);
        require(noRepeat(_owners));
        for (uint256 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
        }
        threshold = _threshold;
    }

    // Well, I know this is epensive. Let's improve it later.
    function noRepeat(address[] memory _owners) internal pure returns (bool) {
        for (uint256 i = 0; i < _owners.length; i++) {
            for (uint256 j = i + 1; j < _owners.length; j++) {
                if (_owners[i] == _owners[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function forward(
        address _dest,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _calldata,
        bytes calldata _extraData
    ) external {
        bytes32 _digest = _computeDigest(_dest, _value, _gasLimit, _calldata);
        GeneralExtensonData memory _data = _extractExtension(_extraData);
        address[] memory endorsers = _extractEndorsers(_digest, _data);
        require(endorsers.length >= threshold);
        require(noRepeat(endorsers));
        for (uint256 i = 0; i < endorsers.length; i++) {
            require(owners[endorsers[i]]); // everyone is a legit endorser
        }
        string memory errorMessage = "Fail to call remote contract";
        (bool success, bytes memory returndata) = _dest.call{value: _value}(
            _calldata
        );
        Address.verifyCallResult(success, returndata, errorMessage);
    }
}
