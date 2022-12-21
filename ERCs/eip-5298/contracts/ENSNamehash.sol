// Original from https://github.com/JonahGroendal/ens-namehash/blob/master/contracts/ENSNamehash.sol
// Licensed under MIT License, https://github.com/JonahGroendal/ens-namehash/blob/master/LICENSE
// Modified by @xinbenlv
// ALL CODE HERE IS FOR A HACKATHON AND IS NOT MEANT TO BE USED IN PRODUCTION

pragma solidity ^0.8.17;

/*
 * @dev Solidity implementation of the ENS namehash algorithm.
 *
 * Warning! Does not normalize or validate names before hashing.
 */
library ENSNamehash {

  function namehash(bytes memory domain) internal pure returns (bytes32) {
    return namehash(domain, 0);
  }

  function namehash(bytes memory domain, uint i) internal pure returns (bytes32) {
    if (domain.length <= i)
      return 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint len = LabelLength(domain, i);

    return keccak256(abi.encodePacked(namehash(domain, i+len+1), keccak(domain, i, len)));
  }

  function LabelLength(bytes memory domain, uint i) private pure returns (uint) {
    uint len;
    while (i+len != domain.length && domain[i+len] != 0x2e) {
      len++;
    }
    return len;
  }

  function keccak(bytes memory data, uint offset, uint len) private pure returns (bytes32 ret) {
    require(offset + len <= data.length);
    assembly {
      ret := keccak256(add(add(data, 32), offset), len)
    }
  }
}
