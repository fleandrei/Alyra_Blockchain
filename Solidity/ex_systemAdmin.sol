pragma solidity 0.6.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Admin is Ownable{
	
	mapping(address=>bool) private Whitelist;
	mapping(address=>bool) private Blacklist;

	event Whitelisted(address _address);
	event Blacklisted(address _address);
	
	constructor () public Ownable(){}

	function whitelist(address _address) public onlyOwner(){
		require(_address != address(0), "You can't whitelist address 0");
		require(Whitelist[_address], "The address is already whitelisted");
		if(Blacklist[_address]){
			Blacklist[_address] = false;
		}
		Whitelist[_address]=true;
		emit Whitelisted(_address);
	}

	function blacklist(address _address) public onlyOwner(){
		require(_address != address(0), "You can't blacklist address 0");
		require(Blacklist[_address], "The address is already Blacklisted");
		if(Whitelist[_address]){
			Whitelist[_address] = false;
		}
		Blacklist[_address]=true;
		emit Blacklisted(_address);
	}

	function isWhitelisted(address _address) public view returns(bool){
		require(_address != address(0), " address 0");
		return Whitelist[_address];
	}

	function isBlacklisted(address _address) public view returns(bool){
		require(_address != address(0), " address 0"); 
		return Blacklist[_address];
	}


}