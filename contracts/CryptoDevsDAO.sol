// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import './Interfaces.sol';

contract CryptoDevsDAO is Ownable {

    struct Proposals {
        uint256 nftTokenId; // the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
        uint256 deadline; // the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 yayVotes; // number of yay votes for this proposal
        uint256 nayVotes; // number of nay votes for this proposal
        bool executed; // whether or not this proposal has been executed yet
        mapping(uint256 => bool) voters; // a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
    }

    mapping(uint256 => Proposals) public proposals; // Create a mapping of ID to Proposal
    uint256 public numProposals; // Number of proposals that have been created

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsToken cryptoDevsNFT;

    // The payable allows this constructor to accept an ETH deposit when it is being deployed
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsToken(_cryptoDevsNFT);
    }

    // which only allows a function to be called by someone who owns at least 1 CryptoDevsNFT
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "You are not a DAO member");
        _;
    }

    function createProposal(uint256 _nftTokenId) external nftHolderOnly returns(uint256) {
        require(nftMarketplace.available(_nftTokenId), "Not for Sale");

        Proposals storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        
        return numProposals - 1;
    }

    modifier activeProposalOnly(uint256 _proposalIndex) {
        require(proposals[_proposalIndex].deadline > block.timestamp, "Deadline Exceeded");
        _;
    }

    // enum for possible actions on proposal
    enum Vote{
        YAY, 
        NAY 
    }

    // function for voting
    function voteOnProposal(uint256 propasalIndex, Vote vote) external nftHolderOnly activeProposalOnly(propasalIndex) {
        Proposals storage proposal = proposals[propasalIndex];

        uint256 voterNftBalance = cryptoDevsNFT.balanceOf(msg.sender);

        uint256 numVotes = 0;

        for(uint256 i = 0; i < voterNftBalance; i++){
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);

            if(proposal.voters[tokenId] == false){
                numVotes++;
                proposal.voters[tokenId] == true;
            }

            require(numVotes > 0, "Already Voted");

            if(vote == Vote.YAY)
                proposal.yayVotes += numVotes;
            else
                proposal.nayVotes += numVotes;
        }
    }

    modifier inactiveProposalsOnly(uint256 proposalIndex){
        require(proposals[proposalIndex].deadline <= block.timestamp, "Deadline Not Exceeded");

        require(proposals[proposalIndex].executed == false, "Propsal already exceeded");
        _;
    }

    function executeProposal(uint256 proposalIndex) external nftHolderOnly inactiveProposalsOnly(proposalIndex) {
        Proposals storage proposal = proposals[proposalIndex];

        if(proposal.yayVotes > proposal.nayVotes){
            uint256 price = nftMarketplace.getPrice();
            require(address(this).balance >= price, "Not enough funds");
            nftMarketplace.purchase{value: price}(proposal.nftTokenId);
        }

        proposal.executed = true;
    }

    function withDraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Contract is empty");
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
    fallback() external payable {}
}

