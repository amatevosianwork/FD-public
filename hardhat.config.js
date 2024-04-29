require("@nomicfoundation/hardhat-toolbox");
require('@solidstate/hardhat-4byte-uploader');
require('@openzeppelin/hardhat-upgrades');
// require('hardhat-gas-reporter')
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {

  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10,
      },
    },
  },
  etherscan: {
    apiKey: {
      polygonAmoy: ''
    },
    customChains: [
      {
        network: "polygonAmoy",
        chainId: 80002,
        urls: {
          apiURL: "https://www.oklink.com/api/explorer/v1/contract/verify/async/api/polygonAmoy",
          browserURL: "https://www.oklink.com/polygonAmoy"
        },
      }
    ]
  },
  networks: {
    polygonAmoy: {
      url: "",
      chainId: 80002,
      accounts: ['', ''],
    },
  },
};
