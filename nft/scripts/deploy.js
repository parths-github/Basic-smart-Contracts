// ether.js comes built in to hardahat
// ether.js is a really nice library to work with ethereum

// Import ethers from Hardhat package
const { ether, ethers } = require("hardhat");


// Script to deploy the contract
async function main() {
    // 1. Tell the script which contract we want to deploy. Here NFTee.sol contract

      /*
       A ContractFactory in ethers.js is an abstraction used to deploy new smart contracts,
       so nftContract here is a factory for instances of our GameItem contract.
      */
     // From the name GameItem hardhat will know that this isthe contract that we want to deploy
    const nftContract = await ethers.getContractFactory("GameItem");

    // 2. Deploy it
    const deployedContract = await nftContract.deploy();
        // 2.1 It might take a while so await for deployment to finish
    await deployedContract.deployed();


    // 3. Print the address of deployed contract
    console.log(deployedContract.address);
}


main()
.then(() => process.exit(0))
.catch((error) => {
    console.log(error);
    process.exit(1);
});




/* It's not all. To deploy contract we have to provide acc from which it gets deployed. In remix we used metamsk so it took care of it without
 revealing our public key. We also need to tell it on which test network to deploy. For that we need to change some configuratio in hardghat
 */ 