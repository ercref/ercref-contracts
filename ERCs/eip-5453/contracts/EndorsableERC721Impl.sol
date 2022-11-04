// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
//
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AERC5453.sol";

contract EndorsableERC721Impl is ERC721, AERC5453 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)
        external
        onlyEndorsed(  // used as modifier
            _tokenId,
            _computeDigest(_from, _to, _tokenId),
            _data // use the full data as endorsement informration
        ),
        override {
        _safeTransfer(from, to, tokenId, "");
    }

    function _eip712DomainTypeHash() pure internal returns (bytes32) {
        return keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    function _eip712DomainSeparator() pure internal returns (bytes) {
        return abi.encode(
            _eip712DomainTypeHash(),
            keccak256("EndorsableERC721Impl"),
            keccak256("1"),
            block.chainid,
            address(this)
        );
    }

    function computeDigest(
        address _from,
        address _to,
        uint256 _tokenId,
    ) external pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                _from,
                _to,
                _tokenId
            )
        );
    }

    function _isEligibleEndorser(uint256 _tokenId, address _endorser) virtual override {
        return _msgSender() == owner || isApprovedForAll(owner, _msgSender());
    }
}
