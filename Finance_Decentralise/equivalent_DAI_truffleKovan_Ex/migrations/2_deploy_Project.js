// 2_deploy_contracts.js
//const Dai = artifacts.require("Dai");
const MyDeFiProject = artifacts.require("MyDeFiProject");
 
module.exports = async function(deployer, _network, accounts) {
 /*await deployer.deploy(Dai);
 const dai = await Dai.deployed();*/
 console.debug("accounts:",accounts);
 const Dai_address = "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa"; //Adresse du smart contrat Dai sur Kovan
 await deployer.deploy(MyDeFiProject, Dai_address); //Dai_address est l'argument du constructeur de MyDeFiProject
 //const myDeFiProject = await MyDeFiProject.deployed();
 //await dai.faucet(myDeFiProject.address, 100);
 /*await myDeFiProject.foo(accounts[1], 100);
 
 const balance0 = await dai.balanceOf(myDeFiProject.address);
 const balance1 = await dai.balanceOf(accounts[1]);
 
 console.log(balance0.toString());
 console.log(balance1.toString());*/
};