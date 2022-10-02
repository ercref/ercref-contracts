import { ethers } from "hardhat";

const deployByName = async (contractName:string, parameters:string[]) => {
  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(...parameters);

  await contract.deployed();

  console.log(`Contract ${contractName} deployed to ${contract.address}`);

}

async function main() {
  await deployByName("ERC5679Ext20RefImpl", ["ERC5679Ext20RefImpl", "ERC5679Ext20RefImpl"]);
  await deployByName("ERC5679Ext721RefImpl", ["ERC5679Ext721RefImpl", "ERC5679Ext721RefImpl"]);
  await deployByName("ERC5679Ext1155RefImpl", ["ERC5679Ext1155RefImpl", "ERC5679Ext1155RefImpl"]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
