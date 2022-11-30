require('@nomiclabs/hardhat-waffle');
require("hardhat-tracer");
require('dotenv').config();
require("hardhat-gas-reporter");

module.exports = {
  solidity: "0.8.9",
  networks: {
    // Ethereum environmentns
    // Binance chain
    bnb_testnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    bsc_mainnet: {
      url: 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY]
    },
    fantom_testnet:{
      url: "https://rpc.testnet.fantom.network",
      chainId: 4002,
      accounts: [process.env.PRIVATE_KEY]
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: [process.env.PRIVATE_KEY_LOCAL]
    },
    optimism_testnet: {
      url: "https://goerli.optimism.io",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 420
    }
  }
}