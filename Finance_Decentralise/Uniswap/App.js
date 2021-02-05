//TP Comment interagir avec le protocole Uniswap ?          Avec javascrit

const path = require("path");
const resultEnv = require('dotenv').config({path: '../EnvVar.env'});
const PrivateKey = process.env.Private_Key.split(",");
const InfuraId = process.env.Infura_Id;
const { ChainId, Fetcher, WETH, Route, Trade, TokenAmount, TradeType, Percent} = require('@uniswap/sdk');
const ethers = require('ethers'); 
/*
  ChainId : pour identifier sur quel réseau nous allons nous connecter 
  Fetcher : pour récupérer des données d’Uniswap 
  Uniswap permet l’utilisation directe du token WETH.
  */

const chainId = ChainId.MAINNET;
const KovanChainId = ChainId.KOVAN;
const tokenAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F'; // DAI address mainnet
const tokenAddressKovan = "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa";
const init = async () => {
	// On récupère les deux token: Retourne des objets de type Token.
	const dai = await Fetcher.fetchTokenData(KovanChainId, tokenAddressKovan); //utilise le provider par défaut de ether.js. If you’re already using ethers.js in your application, you may pass in your provider as a 3rd argument. If you’re using another library, you’ll have to fetch the data separately.
	//const dai = new Token(ChainId.MAINNET, tokenAddress, 18);
	const weth = WETH[KovanChainId];
	console.debug("KovanChainId:",KovanChainId);
	//Pour créer une nouvelle paire sur le market, il suffit d’utiliser le Fetcher comme suit (l’ordre des tokens n’est pas important) 
	const pair = await Fetcher.fetchPairData(dai, weth);

	//Pour créer un nouveau router en se basant sur notre paire et faciliter les interactions.
	/*You may be wondering why we have to construct a route to get the mid price, as opposed to simply getting it from the pair 
	(which, after all, includes all the necessary data). The reason is simple: a route forces us to be opinionated about the direction of 
	trading. Routes consist of one or more pairs, and an input token (which fully defines a trading path). In this case, we passed WETH as
	 the input token, meaning we’re interested in a WETH -> DAI trade.*/
	const route = new Route([pair], weth);
	console.log("\ndai:",dai,"\n weth:",weth,"\npair:",pair,"\nroute:",route);
	//Prix théorique
	console.log(route.midPrice.toSignificant(6)); // combien de DAI pour 1 WETH, avec 6 chiffres significatifs
	console.log(route.midPrice.invert().toSignificant(6)); // le prix inversé 

	//Pour avoir le vrai prix à l’instant t, nous allons avoir besoin de créer un “trade” en spécifiant un amount de token
	const trade = new Trade(route, new TokenAmount(weth, '100000000000000000'), TradeType.EXACT_INPUT);

	//Pour récupérer les prix du trade à l'instant t: 
	console.log(trade.executionPrice.toSignificant(6));
 	console.log(trade.nextMidPrice.toSignificant(6));


 	/*The slippage tolerance encodes how large of a price movement we’re willing to tolerate before our trade will fail to execute. 
 	Since Ethereum transactions are broadcast and confirmed in an adversarial environment, this tolerance is the best we can do to protect 
 	ourselves against price movements. We use this slippage tolerance to calculate the minumum amount of DAI we must receive before our 
 	trade reverts, thanks to minimumAmountOut.*/
 	const slippageTolerance = new Percent('50', '10000'); // tolérance prix 50 bips = 0.050%
 
 	const amountOutMin = trade.minimumAmountOut(slippageTolerance).raw; // minimum des tokens à récupérer avec une tolérance de 0.050%
	const path = [weth.address, dai.address]; // les tokens à échanger
	const to = '';
	const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // le délai après lequel le trade n’est plus valable 
	const value = trade.inputAmount.raw; // la valeur des ethers à envoyer 

	const provider = ethers.getDefaultProvider('kovan', {
   		infura: InfuraId
 	}); // utilisation du provider infura pour effectuer une transaction  
 	
 	const signer = new ethers.Wallet(PrivateKey[0]); // récupérer son wallet grâce au private key
 	const account = signer.connect(provider); // récupérer l’account qui va effectuer la transaction 
 	const uniswap = new ethers.Contract(
   		'0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', //adresse du router uniswap qui reste la même sur main net que sur testnet
   		['function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts)'],
   		account
 	); // récupérer le smart contract d’Uniswap avec l’adress du smart contract et l’ABI. Grâce à ethers on peut passer la fonction à utiliser en solidity 
 	console.debug("\n\nTest\n\n ")
 	const tx = await uniswap.swapExactETHForTokens(
   		amountOutMin,
   		path,
   		to,
   		deadline,
   		{ value, gasPrice: 20e9 }
 	); // envoyer la transaction avec les bons paramètres 
 	console.log(`Transaction hash: ${tx.hash}`); // afficher le hash de la transaction 
 
 	const receipt = await tx.wait(); // récupérer la transaction receipt 
 	console.log(`Transaction was mined in block ${receipt.blockNumber}`);
}
 
init();