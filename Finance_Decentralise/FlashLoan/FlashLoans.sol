// TP Flash Loans    FlashLoans.sol

pragma solidity ^0.6.6;




  /*ILendingPoolAddressesProvider.sol : L’interface qui va permettre l’interaction avec le smart contract d’Aave. Nous aurons besoin de l’address du provider à utiliser, vous avez la liste ici.
    ILendingPool.sol : L’interface du smart contract principal du protocole. Il expose toutes les actions orientées vers l'utilisateur qui peuvent être invoquées en utilisant soit Solidity, soit les bibliothèques web3.
    FlashLoanReceiverBase.sol : Le smart contract qui détermine le LendingPoolAddressProvider à utiliser sur le réseau et qui va nous permettre de manipuler les flash loans d'Aave.
*/

//Pour Remix uniquement
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/FlashLoanReceiverBase.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPoolAddressesProvider.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";

contract FlashLoans is FlashLoanReceiverBase {
   ILendingPoolAddressesProvider provider;
   address dai;
   
   constructor(
       address _provider,
       address _dai)
       FlashLoanReceiverBase(_provider)
       public {
       provider = ILendingPoolAddressesProvider(_provider);
       dai = _dai;
   }

    function flashLoan(uint amount, bytes calldata _params) external {
       // Obtenir un pool de prêts
       ILendingPool lendingPool = ILendingPool(provider.getLendingPool()); 
       // Initialisation du flash loan, en précisant le smart contract qui recevra    le prêt address(this)
       // l'adresse du jeton que vous voulez emprunter et le montant (dai)
       // montant à emprunter (amount)
       lendingPool.flashLoan(address(this), dai, amount, _params);
   }
   
    function executeOperation(// Cette fonction est apppelée par le lendingpool une fois qu'on a récu le loan
       address _reserve,
       uint _amount,
       uint _fee,
       bytes memory _params
    ) override external {
       require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
 
       // La logique du code ! Vous pouvez effectuer : arbitrage, refinance loan, change collateral of loan
       
       uint totalDebt = _amount.add(_fee);
      // remboursement du prêt 
       transferFundsBackToPoolInternal(_reserve, totalDebt); 
    }
   
}