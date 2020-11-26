const Web3 = require('web3');
const rpcURL = "https://ropsten.infura.io/v3/d3a235d3d57c44fb94455d9aff309af9"
const web3 = new Web3(rpcURL)
const ABI = [
	{
		"inputs": [],
		"name": "get",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "x",
				"type": "uint256"
			}
		],
		"name": "set",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]

const SSaddress = "0x8cD906ff391b25304E0572b92028bE24eC1eABFb";
const simpleStorage = new web3.eth.Contract(ABI, SSaddress);
simpleStorage.methods.get().call((err, data) => {
  console.log(data);
});