const path = require("path");
const Web3 = require('web3');
const HDWalletProvider = require('@truffle/hdwallet-provider');
const resultEnv = require('dotenv').config({path: '../EnvVar.env'});
const PrivateKey = process.env.Private_Key;
const InfuraId = process.env.Infura_Id;
const web3 = new Web3(InfuraId);
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    develop: {
      port: 7545
    },

    kovan: {
    provider: () => new HDWalletProvider(PrivateKey, InfuraId),
    network_id: 42,       // Kovan's id
    gas: 7000405 ,    
    gasPrice: web3.utils.toWei('44','gwei'),//44000000000,
    //confirmations: 2,    // # of confs to wait between deployments. (default: 0)
    //timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
    //skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },            
  },

   // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.11",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solcolidity docs for advice about optimization and evmVersion
      optimizer: {
        enabled: false,
        runs: 200
      },
      //  evmVersion: "byzantium"
      // }
    },
  },
};
