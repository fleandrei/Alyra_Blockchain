// Import du smart contract "SimpleStorage"
const Whitelist = artifacts.require("Whitelist");
module.exports = (deployer) => {
 // Deployer le smart contract!
 deployer.deploy(Whitelist);
}