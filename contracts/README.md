# ERCRef Contracts

[![Discord](https://dcbadge.vercel.app/api/server/XDfYyXhH6B?style=flat)](https://discord.io/ERCRef)

A repository for Ethereum builders to build ERC reference implementations.

## Getting Started

Here is how you can start using this repo.

### Use npm package

```sh
npm i -D @ercref/contracts
```
### Useful Templates
- @fulldecent's https://github.com/fulldecent/solidity-template
- @mattstam's https://github.com/mattstam/solidity-template

### Import dependencies

Import the contracts like you would from OpenZeppelin's contract. e.g.

```solidity
import "@ercref/contracts/drafts/IERC5732.sol";
import "@ercref/contracts/drafts/BlocknumGapCommit.sol";
```

Here is a full example:

```solidity
pragma solidity ^0.8.17;

import "@ercref/contracts/drafts/IERC5732.sol";
import "@ercref/contracts/drafts/BlocknumGapCommit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CommitableERC721 is ERC721, BlocknumGapCommit {
    constructor(uint256 _version) ERC721("CommitToMintImpl", "CTMI") {
    }

    function safeMint(
        address _to,
        uint256 _tokenId,
        bytes calldata _extraData
    )   onlyCommited(
            abi.encodePacked(_to, _tokenId),
            bytes32(_extraData[0:32]),
            6 // number of blocks required to reveal
        )
        external {
        _safeMint(_to, _tokenId); // ignoring _extraData in this simple reference implementation.
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, BlocknumGapCommit)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

## Contributors of ERCRef

### Publish `npm`

```sh
yarn publish --access public
```

## Disclaimer and Warnings

*WARNING*: This repository is meant to be cutting (bleeding) edge and pioneer. Please make sure to conduct security audit before using in production.
