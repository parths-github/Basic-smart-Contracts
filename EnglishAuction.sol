// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Seller of NFT deploys this contract.
// Auction lasts for 7 days.
// Participants can bid by depositing ETH greater than the current highest bidder.
// All bidders can withdraw their bid if it is not the current highest bid.

/* After the auction,
* Highest bidder becomes the new owner of NFT.
* The seller receives the highest bid of ETH. */

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint nftId
    ) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address receiver, uint value);
    event End(address highestBidder, uint amount);

    // Address of nft contract
    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    // Time of auction ending, will set when the sellercalls the function started
    uint32 public endAt;
    // A boolean to keep track of staring of auction and ending og auction
    bool public started;
    bool public ended;

    // Keep track of highest bidder
    address public highestBidder;
    // Highestbid
    uint public highestBid;
    // Mapping to keep track of who bided how much
    mapping(address => uint) public bids;


    constructor(uint _startingBid, IERC721 _nft, uint _nftId) {
        nft = _nft;
        seller = payable(msg.sender);
        nftId = _nftId;
        highestBid = _startingBid;

    }

    /* $ function needs to be there
    1. start() - will only be called by owner of contract
    2. bid() - will be able to call by anyone, but the amount must be higher than the current highest bid
               Should also update the mapping, highestBidder, highestBid
    3. withdraw() - will be able to call by bidder, in case they didn't win the auction
    4. end() - can be called by anyone becoz there's might be posiiblity that the owner forgets to end the auction
    */

    function start() external {
        // Should check that auction hasn;t started alraedy
        require(!started, "started");
        require(msg.sender == seller, "not seller");
        // Transfer the ownership of nft to contract
        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = uint32(block.timestamp + 60);
        emit Start();
    }

    // Once the auction is started user will be able to bid
    function bid() external payable {
        // Bid amount must be higher than the current highest bid
        require(msg.value > highestBid, "Amount less than highest bid");
        // Auction must be started and must not be ended
        require(started, "Not Started");
        require(block.timestamp < endAt, "ended");
        // we are not storing the curent highest bidder and highest bifd in mapping, we are only storing the previous highestbidder and their bids
        // Only if there is some bid then update the mapping and there override it
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid; 
        }
        highestBid = msg.value; // IN case of first bidder these 2 lines will execute, and code inside if statement won't execute.
        highestBidder = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    // Only people who are not highest bidder will be able to withdraw 
    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] =  0;
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "not Started");
        require(!ended, "Not ended");
        require(block.timestamp > endAt, "Not ended");

        // So the function will only be able to call once
        ended = true;
        // Incase of noone bidded
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}