// Script is to run the contrcat locally and see if everything goes as expected
const hre = require("hardhat");

// Below are the helper function that we will need un main function
// Returns the balnce of given account
async function getBalance(address) {
  // Provider is node on blockchain that we are talking to, and has getBalance function which returns the balnce of account but in bigInteger
  const balanceBigInt = await hre.waffle.provider.getBalance(address);
  // Ethers has utilis pkg which has formatEther function which formats ether in nicer version
  return hre.ethers.utils.formatEther(balanceBigInt);
}

// Logs the Ether balances for a list of addresses.
async function printBalances(addresses) {
  let idx = 0;
  for (const address of addresses) {
    console.log(`Address ${idx} balance: `, await getBalance(address));
    idx++;
  }
}

// Logs the memos stored on-chain from coffee purchases.
async function printMemos(memos) {
  for (const memo of memos) {
    const timestamp = memo.timestamp;
    const tipper = memo.name;
    const tipperAddress = memo.from;
    const message = memo.message;
    console.log(`At ${timestamp}, ${tipper} (${tipperAddress}) said: "${message}"`);
  }
}

async function main() {
  // Get the example accounts we'll be working with
  const [owner, tipper, tipper2, tipper3] = await hre.ethers.getSigners();

  // Get the contract to deploy
  const BuyMeACoffee = await hre.ethers.getContractFactory("BuyMeACoffee");
  const buyMeACoffee = await BuyMeACoffee.deploy();

  await buyMeACoffee.deployed();
  console.log("BuyMeACoffee deployed to: ", buyMeACoffee.address);

  // Check the balance before coffee purchase
  const addresses = [owner.address, tipper.address, buyMeACoffee.address];
  console.log("== start ==");
  await printBalances(addresses);

  // Buy the owner a few Coffee
  const tip = {value: hre.ethers.utils.parseEther("1")};
  // By .connect we make the address in () the msg.sender
  await buyMeACoffee.connect(tipper).buyCoffee("Carolina", "You're the best!", tip);
  await buyMeACoffee.connect(tipper2).buyCoffee("Vitto", "Amazing teacher", tip);
  await buyMeACoffee.connect(tipper3).buyCoffee("Kay", "I love my Proof of Knowledge", tip);

  // Check balance after coffee purchase
  console.log("== coffee purchase ==");
  await printBalances(addresses);

  // Withdraw
  await buyMeACoffee.connect(owner).withdrawTips();

  // Check balances after withdrawal.
  console.log("== withdrawTips ==");
  await printBalances(addresses);

  // log the memos
  console.log("== memos ==");
  const memos = await buyMeACoffee.getMemos();
  await printMemos(memos);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
