/*
Voting system:
Address that are registered by the admin (the address who lauched the contract) are allowed to submit proposals (during the proposal session) and to vote for them (during the voting session). Proposal and voting sessions are scheduled by the admin. An address is allowed to vote for only one proposal. 
*/


pragma solidity 0.6.11;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";

contract Voting is Ownable{
    using SafeMath for uint;
    struct Voter {
    bool isRegistered;
    bool hasVoted;
    uint votedProposalId;
    }
    
    struct Proposal {
    string description;
    uint voteCount;
    }
    

    enum WorkflowStatus {
    RegisteringVoters,
    ProposalsRegistrationStarted,
    ProposalsRegistrationEnded,
    VotingSessionStarted,
    VotingSessionEnded,
    VotesTallied
    }
    
    uint public winningProposalId;
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus
    newStatus);

    mapping(address=>Voter) Whitelist; //Les élécteurs enregistrés
    Proposal[] Propositions; //Liste des propositions; numérotées à partir de 1.
    WorkflowStatus Etat = WorkflowStatus.RegisteringVoters; //Etats actuel du processus de vote


    /*Enregistre les addresses des élécteurs sur la Whitelist*/
    function RegisterVoter(address _address) public onlyOwner(){
        require(_address != address(0), "Addresse 0");
        require(Etat == WorkflowStatus.RegisteringVoters, "We are not at the Voter Registering stage");
        require(!Whitelist[_address].isRegistered, "Voter address is already registered");

        Whitelist[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }   

    /*Commence la session d'enregistrement de propositions*/
    function BeginProposalStep() public onlyOwner(){
        require(Etat == WorkflowStatus.RegisteringVoters, "Proposal stage must be launched from Voter registration stage");

        Etat = WorkflowStatus.ProposalsRegistrationStarted;
        emit ProposalsRegistrationStarted();
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /*Permet à l'utilisateur appelant de proposer une proposition*/
    function RegisterProposal(string memory _proposalDescription) public {
        require(Etat == WorkflowStatus.ProposalsRegistrationStarted, "We are not at the Proposals registration stage");
        require(Whitelist[msg.sender].isRegistered, "This acount address hasn't been registered");
        /*Vérifie que la proposition n'a pas déjà été proposée*/
        require(!ContainProposal(_proposalDescription), "This proposal has already been submited"); 

        Proposal memory Prop = Proposal(_proposalDescription, 0);
        Propositions.push(Prop);
        emit ProposalRegistered(Propositions.length);
    }

    /*Permet de mettre fin à la session d'enregistrement de proposition*/
    function EndProposalStep() public onlyOwner(){
        require(Etat == WorkflowStatus.ProposalsRegistrationStarted, "End Proposal registration stage but none has started ");
        Etat = WorkflowStatus.ProposalsRegistrationEnded;
        emit ProposalsRegistrationEnded();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);

    }


    /*Permet de vérifier si une proposition a déjà été soumise.*/
    function ContainProposal(string memory _proposalDescription) private view returns(bool){
        uint len = Propositions.length;
        uint i = 0;
        for(i = 1; i <= len; i++){
            if(keccak256(bytes(Propositions[i - 1].description)) == keccak256(bytes(_proposalDescription))){
                return true;
            }
        }
        return false;
    }

    
    function StartVoting() public onlyOwner(){
        require(Etat == WorkflowStatus.ProposalsRegistrationEnded, "The voting stage can begin only after the proposal registration one has ended");

        Etat = WorkflowStatus.VotingSessionStarted;
        emit VotingSessionStarted();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function Vote(uint proposalId) public{
        require(Etat == WorkflowStatus.VotingSessionStarted, "We are not at the Voting stage");
        require(Whitelist[msg.sender].isRegistered, "This acount address hasn't been registered");
        require(!Whitelist[msg.sender].hasVoted, "This account has already voted");
        require((Propositions.length >= proposalId) || proposalId == 0 , "This proposal doesn't exist");
        

        Whitelist[msg.sender].votedProposalId = proposalId;
        Whitelist[msg.sender].hasVoted = true;
        Propositions[proposalId - 1].voteCount = Propositions[proposalId - 1].voteCount.add(1);
        emit Voted (msg.sender,  proposalId);
        
    } 

    function EndVoting() public onlyOwner(){
        require(Etat == WorkflowStatus.VotingSessionStarted, "End the Voting session stage but none has started");

        Etat = WorkflowStatus.VotingSessionEnded;
        emit VotingSessionEnded();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }
    
    function TaillingVotes() public onlyOwner() {
        require(Etat == WorkflowStatus.VotingSessionEnded, "The vote counting stage can begin only after the voting one has ended");
        
        uint Win= 0; //L'identifiant de la proposition gagnante
        uint bestScore = 0; // Meilleur score électoral obtenu
        uint i;
        uint len = Propositions.length;
        for(i = 1; i<=len; i++){
            if(Propositions[i - 1].voteCount > bestScore){
                bestScore = Propositions[i - 1].voteCount;
                Win = i;
            }
        }
        
        winningProposalId = Win;
        
        Etat = WorkflowStatus.VotesTallied;
        emit VotesTallied();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    } 


    
    function WinningProposalDescription() public view returns(string memory){
        require(Etat== WorkflowStatus.VotesTallied, "Vote counting isn't done");
        return Propositions[winningProposalId - 1].description;
    }
        
    
    function WinningProposalScore() public view returns(uint){
        require(Etat== WorkflowStatus.VotesTallied, "Vote counting isn't done");
        return Propositions[winningProposalId - 1].voteCount;
    }
    
    function ProposalNumber() public view returns(uint){
        return Propositions.length;
    }
    
    function ProposalDescriptionById(uint Id) public view returns(string memory){
        require(Id - 1 < Propositions.length, "This proposal doesn't exist");
        return Propositions[Id - 1].description;
    }
    
    function ProposalSocreById(uint Id) public view returns(uint){
         require(Id - 1 < Propositions.length, "This proposal doesn't exist");
        return Propositions[Id - 1].voteCount;
    }
    
    
}