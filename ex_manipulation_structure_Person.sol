pragma solidity 0.7.4;
contract Whitelist {
	struct Person{
		string name;
		uint age;
	}
	function addPerson(string _name, uint age){
		Person memory person = Person("name", 30);
	}
}