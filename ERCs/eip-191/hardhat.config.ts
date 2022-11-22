import { HardhatUserConfig, task } from 'hardhat/config';
import * as dotenv from 'dotenv';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployByName } from './utils/deployUtils';
dotenv.config();
import "@nomicfoundation/hardhat-toolbox";

task('deploy_n_verify', 'Deploy the contracts')
  .setAction(async (args, hre: HardhatRuntimeEnvironment) => {
    const versionHex: string = "0x1002";

    const network = hre.network.name;
    console.log(`start deploy_n_verify version=${versionHex} on network ${network}`);
    await hre.run('compile');

    const results: any[] = [];
    for (const contractName of ['ERC191Impl']) {
      const { contract, tx } = await deployByName(hre.ethers, contractName, [versionHex]);
      results.push({ contract, tx });
    }

    for (const { contractName, contract, tx } of results) {
      // console.log(`Waiting for tx ${tx.hash} to be mined`);
      for (let i = 0; i < 10; i++) {
        console.log(`Block ${i}...`);
        await tx.wait(i);
      }
      console.log(`Done waiting for the confirmation for contract ${contractName} at ${contract.address}`);
      await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: [versionHex],
      }).catch(e => console.log(`Failure ${e} when verifying ${contractName} at ${contract.address}`));
    }
    console.log(`done deploy_n_verify`);
  });

const config: HardhatUserConfig = {
  solidity: "0.8.17",
};

export default config;
