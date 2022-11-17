// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// Import ownershiop
import "@openzeppelin/contracts/access/Ownable.sol";

struct TokenHolding {
    address contractAddress;
    uint256 tokenId;
}

// TODO consider how to handle ERC1155 when amount is involved and can be splitted by multiple owners
contract FirstENSTrust is IERC721Receiver, Ownable {
    // Same address for Mainet, Ropsten, Rinkerby, Gorli and other networks;
    address constant DEFAULT_GLOBAL_ENS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address private ensAddress = DEFAULT_GLOBAL_ENS;
    bytes4 constant ERC721_RECEIVER_MAGICWORD = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    mapping(bytes32 => TokenHolding[]) public erc721NodeToTokenMap;
    mapping(bytes32/*hash of TokenHolding*/ => bytes32/*node of owner*/) public erc721TokenToNodeMap;
    mapping(bytes32/*hash of TokenHolding*/ => mapping(bytes32/*node of owner*/=> uint256)) public erc721NodeToHoldingIndex;

    event AddedToHolding(bytes32 indexed ensNode, address indexed operator, uint256 indexed tokenId);
    event RemovedFromHolding(bytes32 indexed ensNode, address indexed operator, uint256 indexed tokenId);
    function getENS() public view returns (ENS) {
        return ENS(ensAddress);
    }

    function setENS(address newENSAddress) public onlyOwner {
        ensAddress = newENSAddress;
    }

    // @dev This function is called by the owner of the token to approve the transfer of the token
    // @param data MUST BE the ENS node of the intended token receiver this ENSHoldingServiceForNFT is holding on behalf of.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(data.length == 32, "ENSTokenHolder: last data field must be ENS node.");
        // --- START WARNING ---
        // DO NOT USE THIS IN PROD
        // this is just a demo purpose of using extraData for node information
        // In prod, you should use a struct to store the data. struct should clearly identify the data is for ENS
        // rather than anything else.
        bytes32 ensNode = bytes32(data[0:32]);
        // --- END OF WARNING ---

        addToHolding(ensNode, msg.sender, tokenId);
        return ERC721_RECEIVER_MAGICWORD;
    }

    function addToHolding(bytes32 ensNode, address operator, uint256 tokenId) internal {
        emit AddedToHolding(ensNode, operator, tokenId);
        bytes32 tokenHash = keccak256(abi.encodePacked(operator, tokenId));
        erc721NodeToHoldingIndex[ensNode][tokenHash] = erc721NodeToTokenMap[ensNode].length;
        erc721NodeToTokenMap[ensNode]
            .push(TokenHolding(msg.sender, tokenId));
        erc721TokenToNodeMap[tokenHash] = ensNode;
    }

    function removeFromHolding(bytes32 ensNode, address operator, uint256 tokenId) internal {
        emit RemovedFromHolding(ensNode, operator, tokenId);
        bytes32 tokenHash = keccak256(abi.encodePacked(operator, tokenId));
        require(erc721TokenToNodeMap[tokenHash] == ensNode, "ENSTokenHolder: token not in holding");
        uint256 index = erc721NodeToHoldingIndex[ensNode][tokenHash];
        uint256 lastIndex = erc721NodeToTokenMap[ensNode].length - 1;
        TokenHolding memory lastTokenHolding = erc721NodeToTokenMap[ensNode][lastIndex];
        erc721NodeToTokenMap[ensNode][index] = lastTokenHolding;
        bytes32 lastTokenHoldingHash = keccak256(abi.encodePacked(lastTokenHolding.contractAddress, lastTokenHolding.tokenId));
        erc721NodeToHoldingIndex[ensNode][lastTokenHoldingHash] = index;
        erc721NodeToTokenMap[ensNode].pop();
        delete erc721NodeToHoldingIndex[ensNode][tokenHash];
        delete erc721TokenToNodeMap[tokenHash];
    }

    function claimTo(address to, bytes32 ensNode, address tokenConttract, uint256 tokenId) public {
        require(getENS().owner(ensNode) == msg.sender, "ENSTokenHolder: node not owned by sender");
        removeFromHolding(ensNode, tokenConttract, tokenId);
        IERC721(tokenConttract).safeTransferFrom(address(this), to, tokenId);
    }
}
