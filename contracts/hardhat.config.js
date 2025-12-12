require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    mumbai: {
      url: process.env.POLYGON_RPC_URL || "https://polygon-mumbai.g.alchemy.com/v2/demo",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    }
  },
  paths: {
    artifacts: "../app/services/contract_artifacts"
  }
};