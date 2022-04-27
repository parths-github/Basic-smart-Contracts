// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Import the standard implementation ofERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


// GameItem is  ERC721 signifies that the contract we are creating imports ERC721 and follows ERC721 contract from openzeppelin

contract GameItem is ERC721 {
    
    constructor() ERC721("mynft", "MNFT") {
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
    }
}