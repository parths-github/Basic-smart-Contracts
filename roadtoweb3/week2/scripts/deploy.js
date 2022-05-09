const { ethers } = require("hardhat");

async function main() {
    const BuyMeACoffee = await ethers.getContractFactory("BuyMeACoffee");
    const buyMeACoffee = await BuyMeACoffee.deploy();
    await buyMeACoffee.deployed();
    console.log("BuyMeACoffee deployed to: ", buyMeACoffee.address);

}

// Contrcat deployed to : 0x35aF67692Ed7278fE55D29bb7e1f6e95Ecca0c6c

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })