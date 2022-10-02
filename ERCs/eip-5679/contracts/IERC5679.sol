// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity ^0.8.9;

interface IERC5679Ext20 {
   function mint(address _to, uint256 _amount, bytes[] calldata _data) external;
   function burn(address _from, uint256 _amount, bytes[] calldata _data) external;
}

interface IERC5679Ext721 {
   function safeMint(address _to, uint256 _id, bytes[] calldata _data) external;
   function burn(address _from, uint256 _id, bytes[] calldata _data) external;
}

interface IERC5679Ext1155 {
   function safeMint(address _to, uint256 _id, uint256 _amount, bytes[] calldata _data) external;
   function safeMintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
   function burn(address _from, uint256 _id, uint256 _amount, bytes[] calldata _data) external;
   function burnBatch(address _from, uint256[] memory ids, uint256[] memory amounts, bytes[] calldata _data) external;
}
