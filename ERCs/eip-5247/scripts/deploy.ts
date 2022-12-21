import { ethers } from "hardhat";

async function main() {
  const [addr0, addr1, addr2] = await ethers.getSigners();
  const TheResolver = await ethers.getContractFactory("TheResolver");
  const theResolver = await TheResolver.connect(addr2).deploy();

  await theResolver.deployed();

  console.log(`theResolver deployed to ${theResolver.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
