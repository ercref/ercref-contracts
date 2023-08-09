import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-ethers';
import '@openzeppelin/hardhat-upgrades';
import "@nomiclabs/hardhat-ethers";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export async function deployByName(ethers: HardhatRuntimeEnvironment["ethers"], contractName: string, parameters: any[]): Promise<any> /*deployed address*/ {
    console.log(`Deploying ${contractName} with parameters ${parameters}`);
    const contractFactory = await ethers.getContractFactory(contractName);
    const contract = await contractFactory.deploy(...parameters);
    await contract.deployed();
    console.log(`${contractName} deployed to: ${contract.address}`);
    let tx = contract.deployTransaction;
    console.log(`Contract ${contractName} deployed to ${contract.address}`);
    return { contract, tx };
}

export async function deployUpgradableByName(
        ethers: HardhatRuntimeEnvironment["ethers"], 
        upgrades: HardhatRuntimeEnvironment["upgrades"],
        contractName: string, 
        parameters: any[]
    ): Promise<any> /*deployed address*/ {
    console.log(`Deploying upgradable ${contractName} with parameters ${parameters}`);
    const logicFactory = await ethers.getContractFactory(contractName);

    const proxy = await upgrades.deployProxy(
        logicFactory,
        parameters,

        // TODO: remove next line of "unsafeAllow" when the latest openzeppelin upgrades is included in the next release
        // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/commit/15bc82434a56adc1113e70f7b2ad7f2848a641ee#diff-68a1c31fc85cb82c7387ab7dc8c5ae5c1885baeb271cf6e68f67c753d909e0c3L6
        { unsafeAllow: ['delegatecall'] }
    );

    // get implementation for proxy
    const logic = await upgrades.erc1967.getImplementationAddress(proxy.address);
    const proxyAdmin = await upgrades.admin.getInstance();
    return { proxy, logic, proxyAdmin };
}