import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-ethers';
import '@openzeppelin/hardhat-upgrades';
import "@nomiclabs/hardhat-ethers";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export async function deployByName(ethers: HardhatRuntimeEnvironment["ethers"], contractName: string, parameters: string[]): Promise<any> /*deployed address*/ {
    console.log(`Deploying ${contractName} with parameters ${parameters}`);
    const contractFactory = await ethers.getContractFactory(contractName);
    const contract = await contractFactory.deploy(...parameters);
    await contract.deployed();
    console.log(`${contractName} deployed to: ${contract.address}`);
    let tx = contract.deployTransaction;
    console.log(`Contract ${contractName} deployed to ${contract.address}`);
    return { contract, tx };
}
