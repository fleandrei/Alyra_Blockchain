/*SPDX-License-Identifier: UNLICENSED*/
//pragma solidity 0.6.11;
pragma solidity 0.7.4;
contract Whitelist {
	mapping(address=>bool) whitelist;
	event Authorized(address _address);
	
	function authorize(address _address) public {
		whitelist[_address] = true;
		emit Authorized(_address);
	}
}