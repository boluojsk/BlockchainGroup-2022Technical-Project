// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract BlindAuction {

    struct Bid{
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

        // list of all the bids that have been made so far 
        Bid[] availableBids;
        // list of addresses that are allowed to withdraw ether sent when making bid(i.e the bidders who did not win the auction)

        // the Auction window 
        uint auctionEndTime;

        // whether the owner of auction i.e the beneficiary has selected a bid
        bool bidSelected;

        // address of selected bid
        Bid selectedBid;

        // whether the auction has ended
        bool auctionEnded;

        // whether the owner of auction i.e the beneficiary has canceled the auction
        bool auctionCanceled;
        }

    // mapping of NFT_address to auction_objects
    mapping(address=>Auction_Object) public Auction_Objects;


    //maps NFT address to specific bidder address to the withdrawal amount they're supposed to get
    mapping(address=>mapping(address=>uint)) public eligibleWithdrawals;

    // auctionObjects Array;
    Auction_Object[] Auction_Objects_array;
    // mapping of NFT_address to boolean. Necessary for checking whether the NFT is already staked
    mapping(address=>bool) NFT_staked_bool;
    uint NFT_addresses_count = 0;
    address[] NFT_addresses_arr;



    function startAuction(uint min_loan_amount, address NFT_address,uint auction_start_time,uint auction_duration) public{
        // identifies the state of the auction
        // add new Auction Object
        // each has a distinct NFT address
        // need to check that NFT is not already staked
        require(!NFT_staked_bool[NFT_address], "NFT is already staked");
        Auction_Object storage auctionObj = Auction_Objects[NFT_address];
        auctionObj.beneficiary = payable(msg.sender);
        auctionObj.min_loan_amount = min_loan_amount;
        auctionObj.NFT_address = NFT_address;
        auctionObj.auctionEndTime = auction_start_time + auction_duration;
        auctionObj.bidSelected = false;
        auctionObj.auctionCanceled  = false;
        Auction_Objects[NFT_address] = auctionObj;

        // since NFT has been staked change boolean to true
        NFT_staked_bool[NFT_address] = true;
        // just incase: we maintain a list of all current auctioned NFTS
        NFT_addresses_arr.push(NFT_address);
        NFT_addresses_count += 1;

        Auction_Objects_array.push(auctionObj);
    }

    function makeBid(uint loan_amt, uint int_rate, uint repayment_period, address NFT_address) payable public returns(bool){
        Auction_Object storage auctionObj = Auction_Objects[NFT_address];
        require(loan_amt == msg.value, "Loan Amount inconsistent with Ether Sent");
        require(loan_amt >= auctionObj.min_loan_amount,"Loan Amount is less than the minimum required to make this bid");
        require (!auctionObj.auctionEnded, "Auction has Ended");
        require(!auctionObj.auctionCanceled, "Auction was canceled");
        // add bid to availableBids
        auctionObj.availableBids.push(
            Bid(loan_amt, int_rate, repayment_period, msg.sender)
            );
        eligibleWithdrawals[NFT_address][msg.sender] += msg.value;
        return true;
    }

    function selectBid(address selectedLender, address NFT_address) public returns(bool){
    }

    function endAuction(address NFT_address) public {
    }

    function cancelAuction(address NFT_address) public{
    }

    function withdraw(address NFT_address) public{
    }

    // get a single Auction Object for one NFT address
    function getAuctionObject(address NFT_address) public view returns (Auction_Object memory Auct_Obj){
        return Auction_Objects[NFT_address];
    }

    // get all the Auction Objects
    function getAllAuctionObjects() public view returns (Auction_Object[] memory Auct_Objs){
        return Auction_Objects_array;
    }

    // delete NFT listing i.e after the loan has been repayed
    function removeNFTListing(address NFT_address) public {
    }

    // delete an Auction
    function deleteAuction(address NFT_address) public{
    }
}