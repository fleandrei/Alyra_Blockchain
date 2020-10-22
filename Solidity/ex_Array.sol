//pragma solidity 0.6.11;
pragma solidity 0.7.4;

contract Whitelist {
	struct Person{
		string name;
		uint age;
	}
	Person[] public persons;
}