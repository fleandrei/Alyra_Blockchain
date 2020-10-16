pragma solidity 0.6.11;
contract Time {	
	function getTime() public view returns(uint horodate){
		horodate = block.timestamp;
	}
}