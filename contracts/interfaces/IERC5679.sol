// SPDX-License-Identifier: CC0-1.0 or MIT
pragma solidity ^0.8.9;

// The EIP-165 identifier of this interface is 0xd0017968
interface IERC5679Ext20 {
   function mint(address _to, uint256 _amount, bytes calldata _data) external;
   function burn(address _from, uint256 _amount, bytes calldata _data) external;
}

// The EIP-165 identifier of this interface is 0xcce39764
interface IERC5679Ext721 {
   function safeMint(address _to, uint256 _id, bytes calldata _data) external;
   function burn(address _from, uint256 _id, bytes calldata _data) external;
}

// The EIP-165 identifier of this interface is 0xf4cedd5a
interface IERC5679Ext1155 {
   function safeMint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
   function safeMintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
   function burn(address _from, uint256 _id, uint256 _amount, bytes[] calldata _data) external;
   function burnBatch(address _from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata _data) external;
}
