import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-ethers';
import '@openzeppelin/hardhat-upgrades';
import { HardhatUserConfig, task } from 'hardhat/config';
import * as dotenv from 'dotenv';
import "@nomiclabs/hardhat-ethers";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: {
        mnemonic: process.env.MNEMONIC as string,
      },
    },
    gnosis: {
      url: `https://rpc.gnosischain.com`,
      accounts: { mnemonic: process.env.MNEMONIC as string }
    }
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY as string,
    }
  },
};

export default config;
