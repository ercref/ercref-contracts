pragma solidity ^0.8.9;

interface IERCRef {
    event ErcRefImplDeploy(uint256 version, string name, string url);
}

abstract contract AERCRef is IERCRef {
    constructor(string memory _contractName, uint256 _version) payable {
        emit ErcRefImplDeploy(
            _version,
            _contractName,
            "https://www.ercref.org"
        );
    }
}
