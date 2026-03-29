require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const isValidKey = (k) => /^(0x)?[0-9a-fA-F]{64}$/.test(k);
const DEPLOYER_KEY = process.env.DEPLOYER_PRIVATE_KEY || "";
const INVESTOR1_KEY = process.env.INVESTOR1_PRIVATE_KEY || "";
const INVESTOR2_KEY = process.env.INVESTOR2_PRIVATE_KEY || "";

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [DEPLOYER_KEY, INVESTOR1_KEY, INVESTOR2_KEY].filter(isValidKey),
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "",
  },
};