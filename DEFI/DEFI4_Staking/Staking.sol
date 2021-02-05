
// DéFi:  DEFI Staking    Staking.sol    Lancé sur kovan à l'address 0x928aE7b97A3DC66FE4DF7526B43b91508C2BF092
/*Les addresses utilisées dans ce contract sont relatives au réseau testnet Kovan*/

pragma solidity >=0.4.14 <=0.6.12;

import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SignedSafeMath.sol";
//import "https://github.com/Arachnid/solidity-stringutils/strings.sol";

interface Custom_IERC20 is IERC20{
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8) ;
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
    using SafeMath for uint;
    using SignedSafeMath for int;
    /*Structures*/
    
    struct Stake{
        uint amount;
        uint last_reward_withdraw_blockNumber; //Numéro de block auquel le propriétaire a récupéré les intérêts sur le stake
        uint creation_blockNumber;
    }
    
    struct Token{
        string symbol;
        AggregatorV3Interface priceFeed; //Aggator du taux de change 
        bool InEther; //Si true, l'agregator donne le taux de change "token-eth". Si false: "token-usd"
        uint decimal;
    }
    
    //Events
    event EtherStaked(address from, uint amount, uint blockNumber);
    event TokenStaked(address from, uint amount, address tokenAddress, uint blockNumber);
    event EtherUnstaked(address to, uint amount, uint usd_reward);
    event TokenUnstaked(address to, uint amount, address tokenAddress, uint usd_reward);
    event EtherRewardWithdrawn(address to, uint ether_reward, uint usd_reward);
    event TokenRewardWithdrawn(address to, uint Token_reward, uint usd_reward, address tokenAddress);
    event LogUint(uint log);
    
    //State 
    AggregatorV3Interface internal Eth_priceFeed;  // Aggregator du taux de change ETH-USD
    //ENS public ens;
    uint public Interest_rate;
    uint public Interest_decimal;
    //uint Ether_balance;
    Custom_IERC20 public Stake_reward_token; //Token utilisé pour récompensser les stakers. Sa valeur est de 1 dollar
    mapping (address => mapping(address=> Stake[])) Token_Stake; // account address => (ERC20 Token address => Stake list)
    mapping (address => Stake[]) Ether_Stake; // account address => Stake list
    //mapping (address => address[]) Accounts_Token_Address; // Pour chaque account, on stocke la liste des addresses de token qu'il a en stake
    mapping (address => Token) public Tokens_Info; //Informations pour divers Token
    //address[] Token_Address; //Liste des tokens pour lesquels le contract a des stakes.
    //mapping(address => uint) Account_Ether_Balance; //Balance en ether des accounts
    //mapping(address => mapping(address => uint)) Account_Token_Balance; // Pour chaque account, la balance pour chaqun de ses tokens.
    
    modifier Check_Token(address token_address){
        require(address(Tokens_Info[token_address].priceFeed) != address(0), "Unknown Token");
        _;
    }
    
    constructor(
       uint _interest_rate, //Taux d'Intérêt perçu sur les fonds stacké (pourcentage des fonds stacké) par unité de temps (par block).  
       uint _interest_decimal, //Nombre de décimales du taux d'intérêt
       address _stake_reward_token)
       public {
       //Ether_balance=0;
       Interest_rate = _interest_rate;
       Interest_decimal = _interest_decimal;
       Stake_reward_token = Custom_IERC20(_stake_reward_token);
       //ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); //ENS registry address: https://docs.chain.link/docs/ens 
       Eth_priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
       
       /*On stock les informations des tokens que nous allon utiliser. On enregistre notament leur agrégator.*/
       //DAI
       //Token_Address.push(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
       Tokens_Info[0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa] = Token("DAI", AggregatorV3Interface(0x777A68032a88E5A84678A77Af2CD65A7b3c0775a), false, 18);
       //MKR
       //Token_Address.push(0xef13C0c8abcaf5767160018d268f9697aE4f5375);
       Tokens_Info[0xef13C0c8abcaf5767160018d268f9697aE4f5375] = Token("MKR", AggregatorV3Interface(0x0B156192e04bAD92B6C1C13cf8739d14D78D5701), true, 18);
       //BAT
       //Token_Address.push(0x1f1f156E0317167c11Aa412E3d1435ea29Dc3cCE);
       Tokens_Info[0x1f1f156E0317167c11Aa412E3d1435ea29Dc3cCE] = Token("BAT",  AggregatorV3Interface(0x8e67A0CFfbbF6A346ce87DFe06daE2dc782b3219), false, 18);
       //SNX
       Tokens_Info[0x86436BcE20258a6DcfE48C9512d4d49A30C4d8c4] = Token("SNX", AggregatorV3Interface(0x31f93DA9823d737b7E44bdee0DF389Fe62Fd1AcD), false, 18);
       //REP
       Tokens_Info[0x8c9e6c40d3402480ACE624730524fACC5482798c] = Token("REP", AggregatorV3Interface(0x3A7e6117F2979EFf81855de32819FBba48a63e9e), true, 18);
       //ZRX 
       Tokens_Info[0xccb0F4Cf5D3F97f4a55bb5f5cA321C3ED033f244] = Token("ZRX", AggregatorV3Interface(0xBc3f28Ccc21E9b5856E81E6372aFf57307E2E883), true, 18);
  

           
       }
   
    
    /*function get_RewardToken_address() external view returns (address){
        return address(Stake_reward_token);
    }*/
    
   
   
    function Stake_Ether() external payable returns(bool) {
        require(msg.value != 0, "Sent Amount is null");
        require(Decimal_Multiplication(int(msg.value), 18, int(Interest_rate), Interest_decimal.add(2),18)>0, " value too low ");
        
        //Ether_balance= Ether_balance.add(msg.value);
        Ether_Stake[msg.sender].push(Stake(msg.value, block.number, block.number));
        
        
        emit EtherStaked(msg.sender, msg.value, block.number);
        
        return true;
    }
    
    
    function Stake_Token(address token_address, uint amount) external Check_Token(token_address) returns(bool) {
        //require(token_address != address(0), "Token address is null");
        //require(address(Tokens_Info[token_address].priceFeed) != address(0), "Unknown Token");
        require(Decimal_Multiplication(int(amount), Custom_IERC20(token_address).decimals(), int(Interest_rate), Interest_decimal.add(2),18)>0, " value too low ");
        //require(Decimal_Multiplication(int(amount), Tokens_Info[token_address].Instance.decimals(), int(Interest_rate), Interest_decimal.add(2),18)>0, " value too low ");
        
        Custom_IERC20 token = Custom_IERC20(token_address);
        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "contract should get allowance greater or equal to amount");
        
        require(token.transferFrom(msg.sender, address(this), amount)); //On transfer les token du staker sur le smart contract
        
        Token_Stake[msg.sender][token_address].push(Stake(amount, block.number, block.number)); //Si tout se passe bien, on rajoute un stack 
        
        emit TokenStaked(msg.sender, amount, token_address, block.number );
        
        return true;
    }
    
    
    /**
     * @dev Permet à l'utilisateur de récupérer la récompensse qu'il a sur les stake en Ether. Renvoie la valeur de la récompensse en Ether et en Reward_Token(USD)
     * 
     */
    function withdraw_reward_EtherStake() external returns(uint,uint){ 
        uint len = Ether_Stake[msg.sender].length;
        require(len>0, "No ether stacked");
        uint ether_reward = 0;
        
        uint block_diff; // Variable secondaire représentant le nombre de block entre maintenant et la dernière fois où l'on a récupéré les rewards d'un stack.
        
        for(uint i=0; i<len; i++){
            block_diff = block.number.sub(Ether_Stake[msg.sender][i].last_reward_withdraw_blockNumber);
            ether_reward = ether_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Ether_Stake[msg.sender][i].amount), 18, int(Interest_rate), Interest_decimal.add(2), 18)))); // Interest_decimal.add(2) permet de d'avoir Interest_decimal/100 .  En effet Interest_decimal correspond à un pourcentage.
            Ether_Stake[msg.sender][i].last_reward_withdraw_blockNumber = block.number;
        }
        
        require(ether_reward>0, "No reward Available for ether stake");
        
        uint usd_reward = Ether2USD(ether_reward);
        Stake_reward_token.transfer(msg.sender, usd_reward);
        emit EtherRewardWithdrawn(msg.sender, ether_reward, usd_reward);
        
        return (ether_reward, usd_reward); 
    }
    
    
    /**
     * @dev Permet à l'utilisateur de récupérer la récompensse qu'il a sur les stake relatifs à un Token. Renvoie la valeur de la récompensse dans le Token en question ainsi qu'en Reward_Token(USD)
     * 
     */
    function withdraw_reward_TokenStake(address Token_address) external Check_Token(Token_address) returns(uint,uint){ //TO DO
        uint len = Token_Stake[msg.sender][Token_address].length;
        require(len>0, "No token stacked");
        uint Token_reward = 0;
        
        uint block_diff; // Variable secondaire représentant le nombre de block entre maintenant et la dernière fois où l'on a récupéré les rewards d'un stack.
        uint usd_reward;
        
        for(uint i=0; i<len; i++){
            block_diff = block.number.sub(Token_Stake[msg.sender][Token_address][i].last_reward_withdraw_blockNumber);
            Token_reward = Token_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Token_Stake[msg.sender][Token_address][i].amount), 18, int(Interest_rate), Interest_decimal, 18))));
            Token_Stake[msg.sender][Token_address][i].last_reward_withdraw_blockNumber = block.number;
        }
        
        require(Token_reward>0, "No reward Available for this token stake");
        
        if(Tokens_Info[Token_address].InEther){
            usd_reward = Token2Ether(Token_reward, Token_address);
            usd_reward = Ether2USD(usd_reward);
        }else{
            usd_reward = Token2USD(Token_reward, Token_address);
        }
        
        Stake_reward_token.transfer(msg.sender, usd_reward);
        emit TokenRewardWithdrawn(msg.sender, Token_reward, usd_reward, Token_address);
        return (Token_reward, usd_reward);
    }
    
    
     /**
     * @dev Permet à l'utilisateur de retirer des ether du stake et de récupérer la récompensse correspondante. Renvoie la valeur d'ether restante, la récompensse en ether et en
     * Reward_Token (USD)
     * 
     */
    function Unstack_Ether(uint amount) external returns(uint, uint){
        uint index = Ether_Stake[msg.sender].length;
        require(index>0, "No ether stacked");
        require(Decimal_Multiplication(int(amount), 18, int(Interest_rate), Interest_decimal.add(2),18)>0, " value too low ");
        uint amount_to_unstack= amount;
        uint ether_reward =0;
        
        uint block_diff;// Variable secondaire représentant le nombre de block entre maintenant et la dernière fois où l'on a récupéré les rewards d'un stack.
        uint usd_reward;
        
        while(amount_to_unstack>0){
            require(index>0, "Not enough ether staked");
            index = index.sub(1);
            
            if(Ether_Stake[msg.sender][index].amount <= amount_to_unstack){
                amount_to_unstack= amount_to_unstack.sub(Ether_Stake[msg.sender][index].amount);
                
                block_diff = block.number.sub(Ether_Stake[msg.sender][index].last_reward_withdraw_blockNumber);
                ether_reward = ether_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Ether_Stake[msg.sender][index].amount), 18, int(Interest_rate), Interest_decimal, 18))));

                Ether_Stake[msg.sender].pop();
                /*if(amount_to_unstack==0){
                    index=index.sub(1);
                }*/
            }else{
                block_diff = block.number.sub(Ether_Stake[msg.sender][index].last_reward_withdraw_blockNumber);
                ether_reward = ether_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Ether_Stake[msg.sender][index].amount), 18, int(Interest_rate), Interest_decimal, 18))));
                Ether_Stake[msg.sender][index].last_reward_withdraw_blockNumber = block.number;
                
                Ether_Stake[msg.sender][index].amount= Ether_Stake[msg.sender][index].amount.sub(amount_to_unstack);
                amount_to_unstack=0;
            }
            
        }
        
       /* index.sub(1);
        for(uint i= index; i>=0; i--){//On calcule la quantité d'ether restant en stack.
            Stack_Remained= Stack_Remained.add(Ether_Stake[msg.sender][i].amount);
        }*/
        
        msg.sender.transfer(amount);//On retourne les ethers que l'on veut unstack
        
        usd_reward = Ether2USD(ether_reward);
        Stake_reward_token.transfer(msg.sender, usd_reward);//On transfert les frais de récompensse 
        
        emit EtherUnstaked(msg.sender, amount, usd_reward);
        
        return (ether_reward, usd_reward);
    }
    
    
     /**
     * @dev Permet à l'utilisateur de retirer des Token du stake et de récupérer la récompensse correspondante. Renvoie la valeur de Tokens restante, la récompensse en Token et en
     * Reward_Token (USD)
     * 
     */
    function Unstack_Token(uint amount, address token_address) external Check_Token(token_address) returns(uint, uint){
        uint index = Token_Stake[msg.sender][token_address].length;
        require(index>0, "No token stacked");
        require(Decimal_Multiplication(int(amount), Custom_IERC20(token_address).decimals(), int(Interest_rate), Interest_decimal.add(2),18)>0, " value too low ");
        uint amount_to_unstack= amount;
        uint token_reward;
        
        uint block_diff; // Variable secondaire représentant le nombre de block entre maintenant et la dernière fois où l'on a récupéré les rewards d'un stack.
        //uint token_decimal = Tokens_Info[token_address].decimal;
        uint usd_reward;
        uint temp;//Variable temporaire permettant de ne pas avoir d'expressions trop complexes et ainsi d'éviter les erreurs de "Stack too deep"
        
        while(amount_to_unstack>0){
            require(index>0, "Not enough token staked");
            index = index.sub(1);
            
            if(Token_Stake[msg.sender][token_address][index].amount <= amount_to_unstack){
                amount_to_unstack= amount_to_unstack.sub(Token_Stake[msg.sender][token_address][index].amount);
                
                block_diff = block.number.sub(Token_Stake[msg.sender][token_address][index].last_reward_withdraw_blockNumber);
                temp=uint(Decimal_Multiplication(int(Token_Stake[msg.sender][token_address][index].amount), Tokens_Info[token_address].decimal, int(Interest_rate), Interest_decimal,18));
                token_reward = token_reward.add(block_diff.mul(temp));

                //token_reward = token_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Token_Stake[msg.sender][token_address][index].amount), Tokens_Info[token_address].decimal, int(Interest_rate), Interest_decimal))));

                Token_Stake[msg.sender][token_address].pop();
                /*if(amount_to_unstack==0){
                    index=index.sub(1);
                }*/
            }else{
                block_diff = block.number.sub(Token_Stake[msg.sender][token_address][index].last_reward_withdraw_blockNumber);
                temp = uint(Decimal_Multiplication(int(Token_Stake[msg.sender][token_address][index].amount), Tokens_Info[token_address].decimal, int(Interest_rate), Interest_decimal, 18));
                token_reward = token_reward.add(block_diff.mul(temp));
                //token_reward = token_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Token_Stake[msg.sender][token_address][index].amount), Tokens_Info[token_address].decimal, int(Interest_rate), Interest_decimal))));

                Token_Stake[msg.sender][token_address][index].last_reward_withdraw_blockNumber = block.number;
                
                Token_Stake[msg.sender][token_address][index].amount= Token_Stake[msg.sender][token_address][index].amount.sub(amount_to_unstack);
                amount_to_unstack=0;
            }
            
        }
        
        /*for(uint i= index; i>=0; i--){//On calcule la quantité d'ether restant en stack.
            Stack_Remained= Stack_Remained.add(Token_Stake[msg.sender][token_address][i].amount);
        }
        */
        
        Custom_IERC20(token_address).transfer(msg.sender, amount); //On retourne les tokens staked à leur propriétaire 

        //On convertit les frais de récompensses en USD
        if(Tokens_Info[token_address].InEther){
            usd_reward = Token2Ether(token_reward, token_address);
            usd_reward = Ether2USD(usd_reward);
        }else{
            usd_reward = Token2USD(token_reward, token_address);
        }
        
        Stake_reward_token.transfer(msg.sender, usd_reward);//On envoie les frais de récompensses relatifs aux token qui ont été retirés de la sequestre
        
        emit TokenUnstaked(msg.sender, amount, token_address, usd_reward);
        
        return (token_reward, Ether2USD(token_reward));
    }
    
    fallback() payable external{
        require(msg.value==0, "For stacking ether: Call Stack_Ether function");
    }
    
    
    /*function getpricefeed(address token_address) public view returns(int){
        require(token_address != address(0), "Token address is null");
        Custom_IERC20 token = Custom_IERC20(token_address);
        
        string memory symbol = _toLower(token.symbol());
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
    }*/
    
    
    
                    /*GETTERS */
                    
    function get_ether_amount_reward() public view  returns(uint, uint){  
        /*Stake[] memory temp = Ether_Stake[msg.sender];
        require(temp.length>0, "No ether stacked" );*/
        //require(Ether_Stake[msg.sender].length>0,"No ether stacked");
        uint len = Ether_Stake[msg.sender].length;
        require(len > 0, "No Token staked");
        //emit LogUint(len);
        uint ether_reward = 0;
        uint block_diff;
        
        for(uint i=0; i<len; i++){
            block_diff = block.number.sub(Ether_Stake[msg.sender][i].last_reward_withdraw_blockNumber);
            ether_reward = ether_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Ether_Stake[msg.sender][i].amount), 18, int(Interest_rate), Interest_decimal.add(2), 18))));
        }
        
        return (ether_reward, Ether2USD(ether_reward));
        //return(0,0);
    }
    
    function get_Token_amount_reward(address token_address) public view Check_Token(token_address) returns(uint, uint){  
        uint len = Token_Stake[msg.sender][token_address].length;
        require(len > 0, "No Token staked");
        uint Token_reward;
        
        uint block_diff;
        
        for(uint i=0; i<len; i++){
            block_diff = block.number.sub(Token_Stake[msg.sender][token_address][i].last_reward_withdraw_blockNumber);
            Token_reward = Token_reward.add(block_diff.mul(uint(Decimal_Multiplication(int(Token_Stake[msg.sender][token_address][i].amount), 18, int(Interest_rate), Interest_decimal.add(2), 18))));
        }
        
        if(Tokens_Info[token_address].InEther){
            uint reward = Token2Ether(Token_reward, token_address);
            return (Token_reward, Ether2USD(reward));
        }else{
            return (Token_reward, Token2USD(Token_reward,token_address));
        }
        
    }
    
      function get_ether_amount_staked() external view returns(uint){
        uint len = Ether_Stake[msg.sender].length;
        require(len > 0, "No Ether staked");
        uint Amount=0;
        
        for(uint i=0; i<len; i++){
            Amount= Amount.add(Ether_Stake[msg.sender][i].amount);
        }
        return Amount;
    }
    
    
    function get_token_amount_staked(address token_address) external view Check_Token(token_address) returns(uint){
        
        uint len = Token_Stake[msg.sender][token_address].length;
        require(len > 0, "You havn't staked this token");
        uint Amount=0;
        
        for(uint i=0; i<len; i++){
            Amount= Amount.add(Token_Stake[msg.sender][token_address][i].amount);
        }
        return Amount;
    }
    
    
    function get_ether_Stake_number() external view returns(uint){
        return _get_ether_Stake_number(msg.sender);
    } 
    
    function _get_ether_Stake_number(address staker_address) internal view returns(uint){
        require(staker_address!=address(0));
        return Ether_Stake[staker_address].length;
    } 
    
    function get_Token_Stake_number(address token_address) external view Check_Token(token_address) returns(uint){
        return _get_Token_Stake_number(msg.sender, token_address);
    } 
    
    function _get_Token_Stake_number(address staker_address, address token_address) internal view Check_Token(token_address) returns(uint){
        require(staker_address!=address(0));
        return Token_Stake[staker_address][token_address].length;
    } 
    
    function get_Ether_Stake_ById(uint Id) external view returns(uint,uint,uint){
        require(Id<Ether_Stake[msg.sender].length, "Bad Id or empty ether_stacke");
        return (Ether_Stake[msg.sender][Id].amount, Ether_Stake[msg.sender][Id].last_reward_withdraw_blockNumber, Ether_Stake[msg.sender][Id].creation_blockNumber);
    }
    
    function get_Token_Stake_ById(uint Id, address token_address) external view Check_Token(token_address) returns(uint,uint,uint){
        require(Id<Token_Stake[msg.sender][token_address].length, "Bad Id or empty token_stacke");
        return (Token_Stake[msg.sender][token_address][Id].amount, Token_Stake[msg.sender][token_address][Id].last_reward_withdraw_blockNumber, Token_Stake[msg.sender][token_address][Id].creation_blockNumber);
    }
    
    /*function get_Ether_Stakes() external view returns(Stake[] memory){
        return Ether_Stake[msg.sender];
    }
    
    function get_Token_Stakes(address token_address) external view Check_Token(token_address) returns(Stake[] memory){
        return Token_Stake[msg.sender][token_address];
    }*/
    
    
    
    
    
    function get_RewardToken_Symbol() external view returns(string memory){
        return Stake_reward_token.symbol();
    }
    
    function get_RewardToken_ContractSupply() public view returns(uint){
        return Stake_reward_token.balanceOf(address(this));
    }
    
    function get_Token_Balance(address token_address) external view Check_Token(token_address) returns(uint){
        return _get_Token_Balance(token_address);
    }
    
    function _get_Token_Balance(address token_address) internal view Check_Token(token_address) returns(uint){
        //return Tokens_Info[token_address].Instance.balanceOf(address(this));
        return Custom_IERC20(token_address).balanceOf(address(this));
    }
    
    function get_Ether_Balance() external view returns(uint){
        return address(this).balance;
    }
    
                    /*UTILS*/
                    
    /*@dev decimal1 est le nombre de décimal cible: decimal1>=decimal2*/
    /*function Decimal_Multiplication(int nbr1, uint decimal1, int nbr2, uint decimal2) public pure returns(int){
        require(decimal1>=decimal2, " should decimal1 >= decimal2");
        uint diff = decimal1.sub(decimal2);
        return nbr1.mul(nbr2.mul(safePow(10,diff)));
    }*/
    
    /*@dev Multiplie deux nombres décimaux et retourne un résultat ayant un nombre de décimals égal à "target_decimal"*/
    function Decimal_Multiplication(int nbr1, uint decimal1, int nbr2, uint decimal2, uint target_decimal) internal pure returns(int){
        //require(decimal1>=decimal2, " should decimal1 >= decimal2");
        int nbr = nbr1.mul(nbr2);
        uint Decimal = decimal1.add(decimal2);
        if(Decimal<target_decimal){
            nbr= nbr.mul(safePow(10, target_decimal.sub(Decimal)));
        }else if(Decimal>target_decimal){
            nbr= nbr.div(safePow(10, Decimal.sub(target_decimal)));
        }

        return nbr;
    }
    
   /* function return_ether(uint amount, address payable to) public{
        to.transfer(amount);
    }
    
    function return_token(uint amount, address token_address, address to) public{
        //Tokens_Info[token_address].Instance.transfer(to, amount);
        Custom_IERC20(token_address).transfer(to,amount);
    }*/
           
    function safePow(int base, uint exp) internal pure returns(int){
        
        int result =1;
        for(uint i = 0; i<exp; i++){
            result = result.mul(base);
        }
        return result;
    }         
    
    
    function Ether2USD(uint amount) public view returns(uint){ 
        (
            , 
            int price,
            ,
            ,
            
        )=Eth_priceFeed.latestRoundData();
        uint decimal = Eth_priceFeed.decimals();
        return uint(Decimal_Multiplication(int(amount), 18, price, decimal, 18));
    }
    
    function Token2USD(uint amount, address token_address) public view Check_Token(token_address) returns(uint){ 
        require(!Tokens_Info[token_address].InEther, "The pricefeed aggregator should be Token to USD not Token to Ether");
        (
            , 
            int price,
            ,
            ,
            
        )=Tokens_Info[token_address].priceFeed.latestRoundData();
        uint decimal = Tokens_Info[token_address].priceFeed.decimals();
        return uint(Decimal_Multiplication(int(amount), Tokens_Info[token_address].decimal, price, decimal, 18));
    }
    
    function Token2Ether(uint amount, address token_address) public view Check_Token(token_address) returns(uint){ 
        require(Tokens_Info[token_address].InEther, "The pricefeed aggregator should be Token to Ether");
        (
            , 
            int price,
            ,
            ,
            
        )=Tokens_Info[token_address].priceFeed.latestRoundData();
        uint decimal = Tokens_Info[token_address].priceFeed.decimals();
        return uint(Decimal_Multiplication(int(amount), Tokens_Info[token_address].decimal, price, decimal, 18));
    }
    
    /*function string2hash(string memory S) public pure returns(bytes32){
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
    
    }*/
    
}

    