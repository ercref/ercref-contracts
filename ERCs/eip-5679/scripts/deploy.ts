import { ethers } from "hardhat";


async function main() {
  await deployByNameFixture("ERC5679Ext20RefImpl", ["ERC5679Ext20RefImpl", "ERC5679Ext20RefImpl"]);
  await deployByNameFixture("ERC5679Ext721RefImpl", ["ERC5679Ext721RefImpl", "ERC5679Ext721RefImpl"]);
  await deployByNameFixture("ERC5679Ext1155RefImpl", ["ERC5679Ext1155RefImpl", "ERC5679Ext1155RefImpl"]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
