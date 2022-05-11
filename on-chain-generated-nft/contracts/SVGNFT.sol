// give the contract some SVG code
// output an NFT URI with this SVG code
// storing all the nft metadata on-chain

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// yarn add @openzeppelin/contracts- run this in terminal
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// yarn add base64-sol
import "base64-sol/base64.sol";

contract SVGNFT is ERC721URIStorage {
    // @dev to keep details of tokenId
    uint256 public tokenCounter;
    event CraetedSVGNFT(uint256 indexed tokenId, string tokenURI);
    // This is like collection of nfts (everytime we mint nft it will be of type SVG NFT)
    constructor() ERC721 ("SVG NFT", "SVGNFT") {
        tokenCounter = 0;
    }

    function create(string memory _svg) public {
        _safeMint(msg.sender, tokenCounter);
        //Get imageURI
        string memory imageURI = svgToImageURI(_svg);
        // Get tokenURI- In tokenURI there's imageURI
        string memory tokenURI = getTokenURI(imageURI);
        // In ERC721URIStorage.sol, there's a mapping of tokenID to tokenURI, so we have to call the function to set our tokenID to relative tokenURI
        _setTokenURI(tokenCounter, tokenURI);
        emit CraetedSVGNFT(tokenCounter, tokenURI);
        tokenCounter++;
    }

    /* Every nft has metadata which uniquly identifies it.
    It is basically tokenURI - which has name, description, attributes and imageURI
    imageURI - where it's stored. So firstly we have to create imageURI and then stick it to the tokenURI.
    */

    function svgToImageURI(string memory _svg) public pure returns (string memory) {
        // SVGCode - <svg xnlns="http://www.w3.org/2000/svg" height="210" width="400"><path d="M150 0 L75 200 L225 200 Z" /></svg>
        // all imageURI gonna start with - data:image/svg+xml;base64
        // imageURi = data:image/svg+xml;base64, <base64encodedSVGCode>
        string memory baseURL = "data:image/svg+xml;base64,";
        // to convert into base64 encoding there's a library which needs to be included
        // Here encode function takes bytes as input, so have to convert into bytes
        string memory base64encodedSVG = string(Base64.encode(bytes(string(abi.encodePacked(_svg)))));
        // base64encodedSVG - something like this - hefgeg441gf4h64rt6h4164g9s19e7ry9819rey9s791u91999v19879t719ew7989
        //but our baseURL understands it that okayit's base64 encoded
        // Now we have to concat them together
        string memory imageURI = string(abi.encodePacked(baseURL, base64encodedSVG));
        // imageURI - data:image/svg+xml;base64,hefgeg441gf4h64rt6h4164g9s19e7ry9819rey9s791u91999v19879t719ew7989
        return imageURI;
    }

    function getTokenURI(string memory _imageURI) public pure returns (string memory) {
        // tokenURI - starting= data:application/json;base64 (which just tell that the folloeinf strangly looking random string is just base64encoded json object)
        // tokenURI - json = {"name": "SVG NFT", "description": "AN NFT based on SVG", "attributes": "", "image":', _imageURI, '"}
        // tokenURI = starting + <base64encoded-json-object>
        string memory baseURL = "data:application/json;base64,";
        // TokenURI actually shows json object with name, description,attributes and image as key
        // So first make a json object in string form and concate it with imageURI in image field
        // then take base64 encoding of it and then concat it with baseURL
        return string(abi.encodePacked(
            baseURL, 
            Base64.encode(
            bytes(abi.encodePacked(
                '{"name": "SVG NFT", ', 
                '"description": "AN NFT based on SVG", ', 
                '"attributes": "", ',
                '"image":', _imageURI, '"}')))));
        // json is just a json object in string form but we have to convert into base64 encoded in order to make it tokenURI

    }

}