//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


/** In this contract we need randomness in our SVG Code, so we'll use chainlink's
VRF to get the random number. Coz using keccak246 is not complete random and contract can be hacked */

contract RandomSVG is ERC721URIStorage, VRFConsumerBaseV2 {
    // Decalaring interface to connect with vrfcoordinator
    VRFCoordinatorV2Interface COORDINATOR;
    // To make Sure that everytime we mint nft with new tokenId
    uint256 public tokenCounter;
    address payable owner;


    // Subscription Id of Chainlink Subscription (Ideally all should be initialized in constructor, so when we want to deploy the contrcat again with different value we can do that)
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    // Number of value we want from one request
    uint32 numWords =  1;
    uint256 public requestId;   // Chainlink vrf use this method in which one function generates reqId and callback function takes this reqId as argument and proceed the request 


    // SVG parameters
    uint256 constant MAX_PARAMETER = 5;
    uint256 constant MAX_PATH = 5;
    string[] public pathCommands = ["M", "L"];
    string[] public colors = ["red", "blue", "green", "yellow", "black"];

    // Below to mapping are for getting random number from address
    // Mapping to keep track of who requested what req id
    mapping(uint256 => address) public requestIdToSender;
    mapping(uint256 => uint256) public requestIdToTokenID;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event RequestedRandomSVG(uint256 indexed requestId, uint256 indexed tokenId);
    event CreatedUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomWord);
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);


    /// @notice Set some variable 
    /// @param vrfCoordinator_ address of network coordinatorof vrf
    /// @param subscriptionId_ uint256 of vrf subscription
    /// @param keyHash_ bytes32 The gas lane to use, which specifies the maximum gas price to bump to.

    constructor(address vrfCoordinator_, uint64 subscriptionId_, bytes32 keyHash_)
        ERC721("RandomSVG", "rsNFT") 
        VRFConsumerBaseV2(vrfCoordinator_) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        owner = payable(msg.sender);
        s_subscriptionId = subscriptionId_;
        keyHash = keyHash_;
        tokenCounter = 0;
    }

    // 1. Get a random number
    // 2. From that generate random svg code
    // 3. Base64 encode the svg code
    // 4. From that generate tokenURI
    // 5. Mint the nft

    // 1. Get a random number - it makes call to vrf cooordinator's requestRandomwords which takes few parameters and returns the request id and also call the function fulfillRandomWords
    function create() public payable {
        // Assumes the subscription is funded sufficiently.
        // Will revert if subscription is not set and funded(gets checked in vrfcoordinator contrcat)
        // Here we have designed it in a way that it requires some price to mint so weare checking the msg.value.
        require(msg.value >= 100000000000000000, "Not enough fund");
        // Calling the function from vrfcoordinator which returns req Id
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdToTokenID[requestId] = tokenId;
        tokenCounter++;
        emit RequestedRandomSVG(requestId, tokenId);
    }

    // Only owner will be able to call this function 
    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    // Below function returns the random number so, ideally we can put over svg code creation logic in this function body.
    // But this function is called by chainlink vrf so it has some gas limit... so we can't.. we have to write another function for that
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory randomWords
    ) internal override {
        address nftOwner = requestIdToSender[_requestId];
        uint256 tokenId = requestIdToTokenID[_requestId];
        
        // Here i have to call _safeMint function which takes 2 arguments-tkenId and address
        // But in this function i only have reqId... So i need mapping to get toenId and address from rqId
        _safeMint(nftOwner, tokenId);
        tokenIdToRandomNumber[tokenId] = randomWords[0];
        emit CreatedUnfinishedRandomSVG(tokenId, randomWords[0]);
    }

    /// @dev Minting is already done, so function adds tokenUri to tokenId
    function finishMint(uint256 _tokenId) public {
        // Some checks
        require(bytes(tokenURI(_tokenId)).length <= 0, "tokenId already set!");
        require(tokenCounter > _tokenId, "TokenId has not been minted yet");
        require(tokenIdToRandomNumber[_tokenId] > 0, "Need to wait for the Chainlink node to respond!");

        // 2. From random number generate randomSVGCode
        // From tokenID get randomNumber
        uint256 randomNumber = tokenIdToRandomNumber[_tokenId];
        /**  In SVG code we can have multiple path and in each path we can have multiple parameter.
         *  But to save the gas we have to define MAX_PARAMETER and MAX_PATH
         */   
        string memory SVGCode = generateRandomSVG(randomNumber);
        // Get imageURI from svgCode
        string memory imageURI = svgToImageURI(SVGCode);
        // Get tokenURI from imageURI 

        // Set tokenURI to tokenId
        _setTokenURI(_tokenId, getTokenURI(imageURI));
        emit CreatedRandomSVG(_tokenId, SVGCode);

    }

    function generateRandomSVG(uint256 _randomNumber) view private returns (string memory finalSVG) {
        uint256 numberOfPath = (_randomNumber % MAX_PATH) + 1;
        finalSVG = '<svg xmlns="http://www.w3.org/2000/svg" height="500" width="500">';
        for (uint i; i < numberOfPath; i++) {
            string memory pathSVG = generatePath(uint256(keccak256(abi.encode(_randomNumber, i))));
            finalSVG = string(abi.encodePacked(finalSVG, pathSVG));
        }
        finalSVG = string(abi.encodePacked(finalSVG, "</svg>"));
    }

    function generatePath(uint256 _randomNumber) public view returns (string memory pathSVG) {
        uint256 numberOfPathCommands = (_randomNumber % MAX_PARAMETER) + 1;
        pathSVG = "<path d='";
        for (uint i; i < numberOfPathCommands; i++) {
            string memory pathCommand = generatePathCommands(uint256(keccak256(abi.encode(_randomNumber, 500 + i))));
            pathSVG = string(abi.encodePacked(pathSVG, pathCommand));
        }
        string memory color = colors[_randomNumber % colors.length];
        pathSVG = string(abi.encodePacked(pathSVG, "' fill='transparent' stroke='", color,"'/>"));
    }

    function generatePathCommands(uint256 _randomNumber) view public returns (string memory pathCommand) {
        pathCommand = pathCommands[_randomNumber % pathCommands.length];
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, 500 * 2))) % 500;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, 500 * 2 + 1))) % 500;
        pathCommand = string(abi.encodePacked(pathCommand, " ", uint2str(parameterOne), " ", uint2str(parameterTwo)));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

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