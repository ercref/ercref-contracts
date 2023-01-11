// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC5679.sol";

abstract contract ERC5679Ext20 is IERC5679Ext20, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC5679Ext20).interfaceId || super.supportsInterface(interfaceId);
    }
}

abstract contract ERC5679Ext721 is IERC5679Ext721, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC5679Ext721).interfaceId || super.supportsInterface(interfaceId);
    }
}

abstract contract ERC5679Ext1155 is IERC5679Ext1155, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC5679Ext1155).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC165Report {
    function get165(string memory _name) public pure returns (bytes4) {
        if (stringEqual(_name, "IERC5679Ext20")) return type(IERC5679Ext20).interfaceId;
        else if (stringEqual(_name, "IERC5679Ext721")) return type(IERC5679Ext721).interfaceId;
        else if (stringEqual(_name, "IERC5679Ext1155")) return type(IERC5679Ext1155).interfaceId;
        else revert("Unknown interface name");
    }
    function stringEqual(string memory _a, string memory _b) pure public returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }
}
