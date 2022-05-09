const { header } = require("express/lib/request");
const { ethers } = require("hardhat");
const abi = require("../artifacts/contracts/BuyMeACoffee.sol/BuyMeACoffee.json");

async function getBalance(provider, address) {
    const balanceBigInt = await provider.getBalance(address);
    return ethers.utils.formatEther(balanceBigInt);
}

async function main() {
    const contractAddress = "0x35aF67692Ed7278fE55D29bb7e1f6e95Ecca0c6c";
    const contractABI = abi.abi;

    const provider = new ethers.providers.AlchemyProvider("goerli", process.env.RINKEBY_API);
    const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    const buyMeACoffee = new ethers.Contract(contractAddress, contractABI, signer);

    console.log("current balance of owner: ", await getBalance(provider, signer.address), "ETH");
    const contractBalance = await getBalance(provider, buyMeACoffee.address);
    console.log("current balance of contract: ", contractBalance, "ETH");

    if (contractBalance !== "0.0") {
        console.log("withdrawing funds..");
        const withdrawTxn = await buyMeACoffee.withdrawTips();
        await withdrawTxn.wait();
    } else {
        console.log("no funds to withdraw!");
    }

    console.log("current balance of owner: ", await getBalance(provider, signer.address), "ETH");


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })