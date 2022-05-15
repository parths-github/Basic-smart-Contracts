const { ethers } = require("hardhat");

async function main() {
    const whitelistContract = await ethers.getContractFactory("Whitelist");
    const WhitelistContract = await whitelistContract.deploy(10);

    await WhitelistContract.deployed();

    console.log(`WhitelistContract deployed to ${WhitelistContract.address}`);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })