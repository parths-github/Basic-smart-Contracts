const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

async function getBalance(address) {
  const bigInteger = await waffle.provider.getBalance(address);
  return ethers.utils.formatEther(bigInteger);
}

async function printBalances(addresses) {
  let idx = 0;
  for (const address of addresses) {
    console.log(`Address ${idx} balance: `, await getBalance(address));
    idx++;
  }
}

describe("BuyMeACoffee", function () {
  it("Should allow the true caller to call withdraw", async function () {


    
    const BuyMeACoffee = await hre.ethers.getContractFactory("BuyMeACoffee");
    const buyMeACoffee = await BuyMeACoffee.deploy();
  
    await buyMeACoffee.deployed();
    const [owner, tipper1, tipper2] = await ethers.getSigners();
    const tx1 = await buyMeACoffee.connect(tipper2).buyCoffee("Nem", "Jay Neminath", {value: ethers.utils.parseEther("1")});
    await tx1.wait();
    const addresses = [owner.address, tipper1.address, buyMeACoffee.address];
    console.log("== coffee purchase ==");
    await printBalances(addresses);
    const tx2 = await buyMeACoffee.connect(owner).allowWithdrawing(tipper1.address);
    await tx2.wait();
    const tx3 = await buyMeACoffee.connect(tipper2).withdrawTips();
    await tx3.wait();
    console.log("== coffee purchase ==");
    await printBalances(addresses);

    expect(await (getBalance(tipper1.address))).to.greaterThan("10000");


  });
});
