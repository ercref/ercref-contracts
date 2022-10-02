import { ethers } from "hardhat";

async function main() {
  const contractName = "ERC5679Ext20RefImpl";
  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy("ERC5679Ext20RefImpl v1.0.0", "ERC5679Ext20RefImpl");

  await contract.deployed();

  console.log(`Contract ${contractName} deployed to ${contract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
