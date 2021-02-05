// DéFi:  DEFI Staking    Staking.sol

pragma solidity >=0.4.14 <=0.6.12;

import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/Arachnid/solidity-stringutils/strings.sol";

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




contract Staking{
    
    
    struct Stake{
        uint amount;
        uint last_reward_withdraw_blockNumber;
        uint creation_blockNumber;
    }
    
    
    //Events
    event EtherStaked(address from, uint amount, uint blockNumber);
    event TokenStaked(address from, uint amount, address tokenAddress, uint blockNumber);
    
    
    //State 
    AggregatorV3Interface internal priceFeed;
    ENS ens;
    uint public Interest_rate;
    IERC20  Stake_reward_token;
    mapping (address => mapping(address=> Stake[])) Token_Stake; // account address => (ERC20 Token address => Stake)
    mapping (address => Stake[]) Ether_Stake;
    mapping (address => address[]) Token_Address; // Pour chaque account, on stocke la liste des addresses de token qu'il a en stake

    constructor(
       uint _interest_rate,
       address _stake_reward_token)
       public {
           
       Interest_rate = _interest_rate;
       Stake_reward_token = IERC20(_stake_reward_token);
       ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); //ENS registry address: https://docs.chain.link/docs/ens 
   }
   
    
    function get_RewardToken_address() external view returns (address){
        return address(Stake_reward_token);
    }
    
       
   
    function Stake_Ether() external payable {
        require(msg.value != 0, "Sent Amount is null");
        
        Ether_Stake[msg.sender].push(Stake(msg.value, block.number, block.number));
        
        emit EtherStaked(msg.sender, msg.value, block.number);
    }
    
    function Stake_Token(address token_address, uint amount) external {
        require(token_address != address(0), "Token address is null");
        
        Custom_IERC20 Token = Custom_IERC20(token_address);
        uint allowance = Token.allowance(msg.sender, address(this));
        require(allowance >= amount, "contract should get allowance greater or equal to amount");
        
        string memory symbol = _toLower(Token.symbol());
        string memory agregator_ens = concat(symbol, "-usd.data.eth");
        /*Resolver resolver = ens.resolver(agregator_ens);
        address agregatortoken= resolver.addr(agregator_ens);*/
        AggregatorV3Interface TokenpriceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        
        if(Token.transferFrom(msg.sender, address(this), amount)){ //On transfer les token du staker sur le smart contract
            Token_Stake[msg.sender][token_address].push(Stake(amount, block.number, block.number)); //Si tout se passe bien, on rajoute un stack 
        }
        
        emit TokenStaked(msg.sender, amount, token_address, block.number );
        
    }
    
    function getpricefeed(address token_address) public view returns(int){
        require(token_address != address(0), "Token address is null");
        Custom_IERC20 Token = Custom_IERC20(token_address);
        
        string memory symbol = _toLower(Token.symbol());
        string memory agregator_ens_string = concat(symbol, "-usd.data.eth");
        bytes32 byte_ens_agregator = string2hash(agregator_ens_string);
        Resolver resolver = ens.resolver(byte_ens_agregator);
        address agregatortoken= resolver.addr(byte_ens_agregator);
        
        AggregatorV3Interface TokenpriceFeed = AggregatorV3Interface(agregatortoken);
        
         (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = TokenpriceFeed.latestRoundData();
        return price;
    }
    
    
    function string2hash(string memory S) public pure returns(bytes32){
        return keccak256(abi.encodePacked(S));
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

    