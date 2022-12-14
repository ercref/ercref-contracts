// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
// Import ownershiop
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AERC5298.sol";

// TODO consider how to handle ERC1155 when amount is involved and can be splitted by multiple owners
contract FirstENSTrust is AERC5298, Ownable {
    // Same address for Mainet, Ropsten, Rinkerby, Gorli and other networks;
    address constant internal DEFAULT_GLOBAL_ENS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address private ensAddress = DEFAULT_GLOBAL_ENS;

    function getENS() public view returns (ENS) {
        return _getENS();
    }

    function _getENS() internal override view returns (ENS) {
        return ENS(ensAddress);
    }

    function setENS(address newENSAddress) public onlyOwner {
        ensAddress = newENSAddress;
    }

}
