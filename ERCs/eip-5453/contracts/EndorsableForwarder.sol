// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
pragma solidity ^0.8.17;

import "./AERC5453.sol";

contract ThresholdMultiSigForwarder is AERC5453Endorsible {
    mapping(address => bool) private owners;
    uint256 private ownerCount;

    function initialize(
        address[] calldata _owners,
        uint256 _threshold
    ) external {
        require(_threshold >= 1, "Threshold must be positive");
        require(_owners.length >= _threshold);
        require(_noRepeat(_owners));
        super.setThreshold(_threshold);
        for (uint256 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
        }
        ownerCount = _owners.length;
    }

    function forward(
        address _dest,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _calldata,
        bytes calldata _extraData
    )
        onlyEndorsed(
            "function forward(address _dest,uint256 _value,uint256 _gasLimit,bytes calldata _calldata,bytes calldata _extraData)",
            keccak256(abi.encodePacked(_dest, _value, _gasLimit, _calldata)),
            _extraData)
    external {
        string memory errorMessage = "Fail to call remote contract";
        (bool success, bytes memory returndata) = _dest.call{value: _value}(
            _calldata
        );
        Address.verifyCallResult(success, returndata, errorMessage);
    }

    function _isEligibleEndorser(address _endorser) internal override view returns (bool) {
        return owners[_endorser];
    }
}
