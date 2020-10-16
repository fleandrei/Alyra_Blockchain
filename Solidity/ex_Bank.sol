pragma solidity 0.6.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";

contract Bank {
	using SafeMath for uint256; 
	mapping(address => uint) private _balances;	
	function deposit(uint _amount) public{
		_balances[msg.sender].add(_amount);
	}
	function transfer(address _recipient, uint _amount) public {
	    require(_recipient != address(0), "addresse zéro");
	    _balances[msg.sender] = _balances[msg.sender].sub(_amount, "You don't have enough monney");
	    _balances[_recipient] = _balances[_recipient].add(_amount);

	}

	function balanceOf(address _address) public view returns(uint){
		require(_address != address(0), "addresse zéro");
		return _balances[_address];
	}
}
