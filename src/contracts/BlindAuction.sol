// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract BlindAuction {
    struct BlindedBid{
        // blinded/hashed version of bid
        bytes32 hashedBidVal;
        // address of bidder
        address bidder_address;
        // deposit
        uint depositValue;
    }

    struct RevealedBid{
        uint loan_amount;
        uint interest_rate;
        uint repayment_time;
        // address of bidder
        address bidder_address;
    }

    struct Auction_Object{
        // address of the loanee who will receive the loan once the auction ends or they selected a bid
        address payable beneficiary; // the owner of the NFT i.e the person who wants a loan

        // address of NFT 
        address NFT_address;

        // minimum acceptable loan amount
        uint min_loan_amount;

        // maximum interest rate
        uint max_interest_rate;

        // minimum repayment period
        uint min_repayment_period;

        // list of blinded bids
        BlindedBid[] blindedBids;

        // list of revealed bids
        RevealedBid[] revealedBids;

        // the Auction window 
        uint auctionEndTime;

        // whether the owner of auction i.e the beneficiary has selected a bid
        bool bidSelected;

        // address of selected bid
        RevealedBid selectedBid;

        // whether the auction has ended
        bool auctionEnded;

        // whether the owner of auction i.e the beneficiary has canceled the auction
        bool auctionCanceled;

        // whether all bids have been revealed
        bool allBidsRevealed;
        }

    // mapping of NFT_addres to auction_objects
    mapping(address=>Auction_Object) public Auction_Objects;


    //maps NFT address to specific bidder address to their Blinded Bid
    mapping(address=>mapping(address=>BlindedBid[])) public allBlindedBids;

    //maps NFT address to specific bidder address to the withdrawal amt they're supposed to get
    mapping(address=>mapping(address=>uint)) public eligibleWithdrawals;

    // auctionObjects Array;
    Auction_Object[] Auction_Objects_array;
    // mapping of NFT_addess to boolean. Necessary for checking whether the NFT is already staked
    mapping(address=>bool) NFT_staked_bool;
    uint NFT_addresses_count = 0;
    address[] NFT_addresses_arr;

    // makes the Hash value
    function generateHashedBid(uint loan_amt, uint int_rate, uint repayment_period, bool fake) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(loan_amt, int_rate, repayment_period, fake));
    }

    function startAuction(uint min_loan_amount, uint max_interest_rate, uint min_repayment_period, address NFT_address,uint auction_start_time,uint auction_duration) public{
        // identifies the state of the auction
        // add new Auction Object
        // each has a distinct NFT address
        // need to check that NFT is not already staked
        require(!NFT_staked_bool[NFT_address], "NFT is already staked");
        Auction_Object storage auctionObj = Auction_Objects[NFT_address];
        auctionObj.beneficiary = payable(msg.sender);
        auctionObj.min_loan_amount = min_loan_amount;
        auctionObj.max_interest_rate = max_interest_rate;
        auctionObj.min_repayment_period = min_repayment_period;
        auctionObj.NFT_address = NFT_address;
        auctionObj.auctionEndTime = auction_start_time + auction_duration;
        auctionObj.bidSelected = false;
        auctionObj.auctionCanceled  = false;
        auctionObj.allBidsRevealed = false;
        Auction_Objects[NFT_address] = auctionObj;

        // since NFT has been staked change boolean to true
        NFT_staked_bool[NFT_address] = true;
        // just incase: we maintain a list of all current auctioned NFTS
        NFT_addresses_arr.push(NFT_address);
        NFT_addresses_count += 1;

        Auction_Objects_array.push(auctionObj);
    }
    
    function makeBid(uint loan_amt, uint int_rate, uint repayment_period, bool fake, address NFT_address) payable public{
        Auction_Object storage auctionObj = Auction_Objects[NFT_address];
        require (!auctionObj.auctionEnded, "Auction has Ended");
        require(!auctionObj.auctionCanceled, "Auction was canceled");
        // ensure that bidder is not making the same bid
        bytes32 HashVal = generateHashedBid(loan_amt, int_rate, repayment_period, fake);
        BlindedBid[] storage bidsToCheck = allBlindedBids[NFT_address][msg.sender];
        for(uint i = 0; i < bidsToCheck.length; i++){
            require(bidsToCheck[i].hashedBidVal != HashVal, "You've already placed this bid before");
        }
        // add bid to availableBids
        auctionObj.blindedBids.push(
            BlindedBid(HashVal, msg.sender, msg.value
            ));
        allBlindedBids[NFT_address][msg.sender].push(
            BlindedBid(HashVal, msg.sender, msg.value
            )
        );
    }

    function revealBid(uint[][] memory allSentLoanTerms, bool[] memory fake_, address NFT_address) public{

    }

    function selectBid(address selectedLender, address NFT_address) public returns(bool){
       
    }

    function endAuction(address NFT_address) public {
        Auction_Object storage auctionObj = Auction_Objects[NFT_address];
        require(!auctionObj.auctionEnded, "Auction already ended");
        require(!auctionObj.auctionCanceled, "Auction already canceled");
        require(block.timestamp >= auctionObj.auctionEndTime, "Auction duration has not elapsed yet");

        auctionObj.auctionEnded = true;
    }

    function cancelAuction(address NFT_address) public{
        Auction_Object storage auctionObj = Auction_Objects[NFT_address];
        require(!auctionObj.auctionEnded, "Auction already ended");
        require(!auctionObj.auctionCanceled, "Auction already canceled");
        require(!auctionObj.bidSelected, "Bid already selected");

        auctionObj.auctionCanceled = true;
    }

    // Allows bidders whose bids were not selected to withdraw the ether they had bid.
    //The function is only viewable by the bidders-> frontend

    // for the selected bidder who has made more than one bit, it needs to return the bids that are not selected
    function withdraw(address NFT_address) public 
    {
        Auction_Object storage auctionObj = Auction_Objects[NFT_address];
        require(auctionObj.auctionEnded, "Auction has not ended yet");
        require(auctionObj.bidSelected, "The auction owner has not selected a bid yet");
        uint256 amount = eligibleWithdrawals[NFT_address][msg.sender];

        // a more secure way to do this??
        // https://docs.soliditylang.org/en/v0.8.7/common-patterns.html
        if (amount > 0) {
            // Set the account's eligible withdrawal to zero
            eligibleWithdrawals[NFT_address][msg.sender] = 0;
            // pay back the money they sent
            // read that call is better than transfer for receiving money????
            payable(msg.sender).transfer(amount);
        }
    }

    // get a single Auction Object for one NFT address
    function getAuctionObject(address NFT_address) public view returns (Auction_Object memory Auct_Obj)
    {
        return Auction_Objects[NFT_address];
    }

    // get all the Auction Objects
    function getAllAuctionObjects() public view returns (Auction_Object[] memory Auct_Objs)
    {
        return Auction_Objects_array;
    }

    // delete NFT listing i.e after the loan has been repayed
    function removeNFTListing(address NFT_address) public 
    {

    }

    // delete an Auction
    function deleteAuction(address NFT_address) public 
    {

    }

    //return eligible withdrawal amt bidder is entitled to from a certain auction -> just for testing purposes
    function showEligibleWithdrawal(address NFT_address) public view returns (uint256)
    {
        return eligibleWithdrawals[NFT_address][msg.sender];
    }
}