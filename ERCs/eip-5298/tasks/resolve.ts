import { EtherscanProvider } from "@ethersproject/providers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { task } from "hardhat/config";
import type { TaskArguments } from "hardhat/types";

task("resolve", "Mints tokens to an address")
  .addParam("signerIndex", "Address of contract of theResolver.")
  .addParam("point", "Address of contract of theResolver.")
  .addParam("ens", "ENS such as xinbenlv.eth")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const network = await ethers.provider.getNetwork();
    console.log("network", network);
    let resolver = await ethers.provider.getResolver(taskArguments.ens);
    let address = await ethers.provider.resolveName(taskArguments.ens);
    console.log(`resolver: ${resolver}`, `address: ${address}`);

    console.log(`-------------`);
    const signer = (await ethers.getSigners())[parseInt(taskArguments.signerIndex)] as SignerWithAddress;
    let contract = await ethers.getContractAt("TheResolver", taskArguments.point);
    const jsNamehash = ethers.utils.namehash(taskArguments.ens);
    const solNamehash = await contract.computeNamehash(taskArguments.ens);
    console.log(`jsNamehash =`, jsNamehash);
    console.log(`solNamehash =`, solNamehash);
    let result = await contract.connect(signer).resolveFromName(taskArguments.ens);
    console.log(`result: ${result}`);
  });
