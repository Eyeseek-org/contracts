require('@nomiclabs/hardhat-waffle');
require("hardhat-tracer");
require('dotenv').config();
//require("hardhat-gas-reporter");
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const { task } = require("hardhat/config");

const {
  API_URL_MUMBAI,
  API_URL_OPTIMISM,
} = process.env;


task("account", "returns nonce and balance for specified address on multiple networks")
  .addParam("address")
  .setAction(async address => {
    const web3Mumbai = createAlchemyWeb3(API_URL_MUMBAI);
    const web3Opt = createAlchemyWeb3(API_URL_OPTIMISM);

    const networkIDArr = [ "Polygon  Mumbai:", "Optimism Goerli:"]
    const providerArr = [ web3Mumbai, web3Opt];
    const resultArr = [];
    
    for (let i = 0; i < providerArr.length; i++) {
      const nonce = await providerArr[i].eth.getTransactionCount(address.address, "latest");
      const balance = await providerArr[i].eth.getBalance(address.address)
      resultArr.push([networkIDArr[i], nonce, parseFloat(providerArr[i].utils.fromWei(balance, "ether")).toFixed(2) + "ETH"]);
    }
    resultArr.unshift(["  |NETWORK|   |NONCE|   |BALANCE|  "])
    console.log(resultArr);
  });

  // Need to have same nonce --> New address for prod deployment each time  

module.exports = {
  solidity: "0.8.17",
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
      url: API_URL_MUMBAI,
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
      url: API_URL_OPTIMISM,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 420
    }
  }
}