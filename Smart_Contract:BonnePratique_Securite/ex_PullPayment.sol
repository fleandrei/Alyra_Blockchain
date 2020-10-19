pragma solidity 0.6.11;

contract PullPayment{
	mapping(address=>uint) public Credits;
	
	function IncreaseBalance(address _address, uint amount) private {
		Credits[_address] += amount;
	}

	function PullFunds(uint _amount) public{
		uint credit = Credits[msg.sender];
		require(_amount > 0);
		require(credit >= _amount);
		require(address(this).balance >= _amount);


		Credits[msg.sender] -= _amount;
		msg.sender.transfer(_amount);
	}

}