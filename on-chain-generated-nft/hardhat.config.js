require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers")
require("hardhat-deploy")
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();


const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  // setting hardhat as default network
  defaultNetwork: "hardhat",
  // Set different networks
  networks: {
    // leaving empty as hardhat will do it 
    hardhat: { },
    rinkeby: {
      url: RINKEBY_RPC_URL,
      accounts: [PRIVATE_KEY],
      saveDeployments: true
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  },
  solidity: {
    compilers: [
      {version : "0.8.4"}, {version: "0.6.6"}, {version: "0.7.0"}, {version: "0.4.24"}
    ]
  },
  namedAccounts: {
    deployer: {
    // Telling to use first accounts
    default: 0
    }
  }
};
