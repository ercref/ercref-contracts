pragma solidity ^0.8.9;

interface IERC137Registry {
    event NewOwner(bytes32 indexed, bytes32 indexed, address);
    event NewResolver(bytes32 indexed, address);
    event Transfer(bytes32 indexed, address);

    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function setOwner(bytes32 node, address owner) external ;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setTTL(bytes32 node, uint64 ttl) external;
}

interface IERC137ResolverCore {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC137ResolverContract {
    event AddrChanged(bytes32 indexed node, address addr);
    function addr(bytes32 node) external view returns (address);
}
