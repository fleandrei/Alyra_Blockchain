pragma solidity >=0.4.14 <=0.6.12;

import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

interface Custom_IERC20 is IERC20{
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
}


// ENS Registry Contract
interface ENS {
    function resolver(bytes32 node) external view returns (Resolver);
}

// Chainlink Resolver
interface Resolver {
    function addr(bytes32 node) external view returns (address);
}


contract test_utils{
    
    ENS public ens;
    
    constructor()public {
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); //ENS registry address: https://docs.chain.link/docs/ens 
    }
    
    
    event logInt(int log);
    event logString(string log);
    event logUint(uint log);
    event logUint80(uint80 log);
    
    function string2hash(string memory S) public pure returns(bytes32){
        //return keccak256(abi.encode(S));
        return sha256(abi.encode(S));
        //return sha3(abi.encodePacked(S));
    }
    
    
     function getpricefeed(address token_address) public returns(int){
        require(token_address != address(0), "Token address is null");
        Custom_IERC20 Token = Custom_IERC20(token_address);
        
        string memory symbol = _toLower(Token.symbol());
        string memory agregator_ens_string = concat(symbol, "-usd.data.eth");
        
        emit logString(concat("symbole: ",Token.symbol()));
        emit logString(concat("name: ",Token.name()));
        emit logString(concat("ens_string: ",agregator_ens_string));
        
        bytes32 byte_ens_agregator = string2hash(agregator_ens_string);
       /* Resolver resolver = ens.resolver(byte_ens_agregator);
        address agregatortoken= resolver.addr(byte_ens_agregator);*/
        Resolver resolver = ens.resolver(0xf599f4cd075a34b92169cf57271da65a7a936c35e3f31e854447fbb3e7eb736d);
        //address agregatortoken= resolver.addr(0xf599f4cd075a34b92169cf57271da65a7a936c35e3f31e854447fbb3e7eb736d);*/
        
        AggregatorV3Interface TokenpriceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        
         (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = TokenpriceFeed.latestRoundData();
        emit logUint80(roundID);
        emit logInt(price);
        emit logUint(startedAt);
        emit logUint(timeStamp);
        emit logUint80(answeredInRound);
        
        return price;
        
    }
    
    
   
    function _toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    function concat(string memory a, string memory b) public pure returns (string memory) {

        return string(abi.encodePacked(a, b));
    
    }
}