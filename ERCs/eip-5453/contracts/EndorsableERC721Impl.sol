// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AERC5453.sol";

contract EndorsableERC721Impl is ERC721, AERC5453 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)
        public
            onlyEndorsed(  // used as modifier
                _tokenId,
                _computeDigest(_from, _to, _tokenId, _data[:_data.length - AERC5453.LENGTH_OF_ENDORSEMENT]),
                _data[:AERC5453.LENGTH_OF_ENDORSEMENT]
            ),
    )
        override {
        _safeTransfer(from, to, tokenId, data[_data.length - AERC5453.LENGTH_OF_ENDORSEMENT:]);
    }

    function _computeDigest(address _from, address _to, uint256 _tokenId, bytes calldata _extraData) internal pure returns (bytes32) {
        uint256 remainLength = _extraData.length - AERC5453.LENGTH_OF_ENDORSEMENT;
        return keccak256(
            abi.encodePacked(
                from, to, id, amount,
                extraData[:remainLength], // first part of extraData is reserved for original use for extraData unendorsed.
                extraData[remainLength: remainLength + 32], // nonce of endorsement for the {contract, endorser} combination
                extraData[remainLength + 32: remainLength + 64], // valid_by for the endorsement
            )
        );
    }

    function _isEligibleEndorser(uint256 _tokenId, address _endorser) virtual override {
        return _msgSender() == owner || isApprovedForAll(owner, _msgSender());
    }
}
