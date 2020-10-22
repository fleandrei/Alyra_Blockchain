pragma solidity ^0.5.12;
 
contract Crowdsale {
   using SafeMath for uint256;
 
   address public owner; // the owner of the contract
   address public escrow; // wallet to collect raised ETH
   uint256 public savedBalance = 0; // Total amount raised in ETH
   mapping (address => uint256) public balances; // Balances in incoming Ether
 
   // Initialization
   function Crowdsale(address _escrow) public{
      require(_escrow != address(0), "escrow address is null");
       owner = msg.sender;
       // add address of the specific contract
       escrow = _escrow;
   }
  
   // function to receive ETH
   function() public payable {
       balances[msg.sender] = balances[msg.sender].add(msg.value);
       savedBalance = savedBalance.add(msg.value);
       escrow.transfer(msg.value);
   }
  
   // refund investisor
   function withdrawPayments() public{
       address payee = msg.sender;
       uint256 payment = balances[payee];
 
      savedBalance = savedBalance.sub(payment);
      balances[payee] = 0;

      payee.transfer(payment);
 
       
   }
}
