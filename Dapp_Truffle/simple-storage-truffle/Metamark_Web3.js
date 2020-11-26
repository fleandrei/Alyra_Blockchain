const Web3 = require('web3');
var web3;
async function loadWeb3() {
   if (window.ethereum) {
    web3 = new Web3(window.ethereum) // permet d’initialiser l’objet Web3 en se basant sur le provider injecté dans la page web 
    await window.ethereum.enable() //demande à Metamask de laisser la page web accéder à l’objet web3 injecté
    console.log("window.ethereum",window.ethereum,"\n");
   }
   else if (window.web3) {
    window.web3 = new Web3(window.web3.currentProvider) // si l’objet web3 existe déjà, l’objet Web3 est initialisé en se basant sur le provider du web3 actuel
    console.log("window.web3",window.web3,"\n");
   }
   else {
     window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!') // message d’erreur si le navigateur ne détecte pas Ethereum
   }
 }

 loadWeb3();

  /*web3.eth.getBalance("0xb8c74A1d2289ec8B13ae421a0660Fd96915022b1", (err, wei) => {  
  balance = web3.utils.fromWei(wei, 'ether'); // convertir la valeur en ether 
  console.log(balance);
});*/