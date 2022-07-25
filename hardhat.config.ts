// import {HardhatUserConfig} from "hardhat/config";
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import 'dotenv/config';
import '@nomiclabs/hardhat-etherscan';

module.exports = {
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './tests'
  },
  solidity: "0.8.15",

  networks: {
    rinkeby: {
      url: process.env.DEPLOY_KEY_RINKEBY,
      accounts: [process.env.DEPLOY_ACC_RINKEBY],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
