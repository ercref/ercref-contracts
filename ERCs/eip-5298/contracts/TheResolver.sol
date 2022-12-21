// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
// Registry
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "./ENSNamehash.sol";

contract TheResolver {
    // Same address for Mainet, Ropsten, Rinkerby, Gorli and other networks;
    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    using ENSNamehash for bytes;
    function computeNamehash(string memory _name)
        public
        pure
        returns (bytes32 namehash)
    {
        return bytes(_name).namehash();
    }

    function resolveFromName(string memory _name) public view returns (address) {
        bytes32 namehash = computeNamehash(_name);
        Resolver resolver;
        resolver = Resolver(ens.resolver(namehash));
        return resolver.addr(namehash);
    }
}
