// DeFi: DAI sur le testnet Kovan
var Tx = require('ethereumjs-tx').Transaction;
const Web3 = require('web3');
require('dotenv').config({path:"EnvVar.env"});
const Infura_Id = process.env.Infura_Id;
const Private_Key = process.env.Private_Key.split(",");
const web3 = new Web3(Infura_Id);	
const Contract_Address = "0x09eCE05672978b6d9bA547D22a8821AEE3B0ba13";
const account1 = '0x97045b2FAB7a709C5C8E946A8896b5EaeBCE08fC'; // Your account address 1
const account2 = '0x96C2Ba4E14604BD4e0Bc218Ce3C4973F0D9Be49C';
const privateKey1 = Buffer.from(Private_Key[0], 'hex');

// Deploy the contract
web3.eth.getTransactionCount(account1, (err, txCount) => {
	const foo_Interface = {
		name:"foo", 
		type:"function", 
		inputs:[{
			type:"address", 
			name:"recipient"
		},{
			type:"uint256",
			name:"amount"
		}]
	};

	const data = web3.eth.abi.encodeFunctionCall(foo_Interface, ["0x96C2Ba4E14604BD4e0Bc218Ce3C4973F0D9Be49C",web3.utils.toWei("7","ether")]);

   	const txObject = {
   		nonce:    web3.utils.toHex(txCount),
   		gasLimit: web3.utils.toHex(1000000), // Raise the gas limit to a much higher amount
   		gasPrice: web3.utils.toHex(web3.utils.toWei('10', 'gwei')),
   		to: Contract_Address,
   		data: data
 	};

 	var tx = new Tx(txObject, {'chain':'kovan'});
 	console.debug("Tx:",tx);
 	console.debug("privateKey1:",privateKey1);
 	tx.sign(privateKey1);
 	console.debug("Tx signed:",tx);

 	const serializedTx = tx.serialize();
 	console.debug("serializedTx:",serializedTx);
 	const raw = '0x' + serializedTx.toString('hex');
 	console.debug("raw:",raw);
 	web3.eth.sendSignedTransaction(raw, (err, txHash) => {
   		console.log('err:', err, 'txHash:', txHash);
   	// Use this txHash to find the contract on Etherscan!
 	});
});
