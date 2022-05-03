// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Seller of NFT deploys this contract setting a starting price for the NFT.
// Auction lasts for 7 days.
// Price of NFT decreases over time.
// Participants can buy by depositing ETH greater than the current price computed by the smart contract.
// Auction ends when a buyer buys the NFT.

interface IERC721 {
    function transferFrom (
        address _from,
        address _to,
        uint _nftId
    )external;
}

/* In ductch auction, Initially the seller sets the price and every second the price reduces to fixed amount.
* When someone feels like price is worth it and want to buy then he can by it.
* In our project we Its the auction of NFT which is erc721. */


/* Here we have included the interface of ERC721 contract, where we have deployed that contrcat and minted one nft.
* Here we'll take address of that contract and will call the above transferFrom function while selling the nft when 
* someone calls the buy function */

contract DutchAuction {
    // Set the duration of auction
    uint private constant DURATION = 7 days;

    // By including immutable we can save gas. All of the variable 
    // which are gonna be constant but have to be set during deploying the contract
    // In construction coz their value will are not known by the time of writing the code.
    IERC721 public immutable nft;
    uint public immutable nftId;

    // Seller will be the one who owns the nft and will receive the amount, so it's payable
    address payable public immutable seller;
    // Set the staring price of nft
    uint public immutable startingPrice;
    // Set the time- it will be block.timestamp
    uint public immutable startAt;
    uint public immutable expireAt;
    uint public immutable discountRate;

    constructor(
        uint _startingPrice,
        uint _discountRate,
        IERC721 _nft,
        uint _nftId
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp;
        expireAt = block.timestamp + DURATION;
        discountRate = _discountRate;

        // Here price is constantly descreasing so we have to make sure that by the end of the duration it doesn't reaches to 0
        // Here i can't access the immutable variable inside the constructor, so i have to use the inputs
        require(_startingPrice >= _discountRate * DURATION, "Staring price < min");

        nft = _nft;
        // Will come from when we mint the nft
        nftId = _nftId;
    }

    // Function to let the user know the current price and also to access during selling
    function getPrice() public view returns (uint) {
        uint discount = (block.timestamp - startAt) * discountRate;
        return startingPrice - discount;
    }

    function buy() external payable {
        // Need to check that auction is still valid
        require(block.timestamp < expireAt, "Auction expired");

        uint price = getPrice();
        // Check that buyer has provided more ether than price or equal
        require(msg.value >= price, "ETH < price");

        nft.transferFrom(seller, msg.sender, nftId);
        // Refund the extraamount if any
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        // Once the selling is done we need to destruct the contract so no othe buyer is ablie to call it
        // It will transfer the amount in contract to seller
        selfdestruct(seller);
    }
}