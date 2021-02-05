//Lancé sur Kovan à l'address  0x25f6C67015F67c0FB41C37Cb85ba836Df25DAbB6
pragma solidity >=0.4.14 <=0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";


contract Reward_Token is ERC20, Ownable{
    
  
    
    constructor(string memory name_, string memory symbol_, uint InitialSupply) ERC20(name_, symbol_) public{
        _mint(msg.sender, InitialSupply);
    }
    
    function mint_token(uint supply, address account) external onlyOwner() {
        _mint(account, supply);
    }
    
    
}