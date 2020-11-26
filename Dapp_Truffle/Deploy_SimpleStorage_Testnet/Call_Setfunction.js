var Tx     = require('ethereumjs-tx').Transaction;
const Web3 = require('web3');
require('dotenv').config({path:"../EnvVar.env"});
const web3 = new Web3('https://ropsten.infura.io/v3/d3a235d3d57c44fb94455d9aff309af9')
const ABI = [ { "inputs": [ { "internalType": "uint256", "name": "x", "type": "uint256" } ], "name": "set", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "get", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function", "constant": true } ];
const SSaddress = "0xCbd43b4CF42101693689a1f9C201471d8f505E8f";
const account1 = '0x97045b2FAB7a709C5C8E946A8896b5EaeBCE08fC'; // Your account address 1
const Private_Key = process.env.Private_Key;
const privateKey1 = Buffer.from(Private_Key, 'hex');


web3.eth.getTransactionCount(account1, (err, txCount) => {
 const simpleStorage = new web3.eth.Contract(ABI, SSaddress);
 const data = simpleStorage.methods.set(7).encodeABI();

  const txObject = {		
   nonce:    web3.utils.toHex(txCount),
   gasLimit: web3.utils.toHex(70000), // Raise the gas limit to a much higher amount
   gasPrice: web3.utils.toHex(web3.utils.toWei('100', 'gwei')),
   to: SSaddress,
   data: data
 }

 var tx = new Tx(txObject, {'chain':'ropsten'});
 tx.sign(privateKey1)

 const serializedTx = tx.serialize()
 const raw = '0x' + serializedTx.toString('hex')

 web3.eth.sendSignedTransaction(raw, (err, txHash) => {
   console.log('err:', err, 'txHash:', txHash)
   // Use this txHash to find the contract on Etherscan!
 })
})