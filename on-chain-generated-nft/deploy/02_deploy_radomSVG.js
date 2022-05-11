
const { networkConfig } = require("../helper-hardhat-config");


module.exports = async({
    deployments,
    getNamedAccounts,
    getChainId
}) => {
    const { deploy, get, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();

    // const decimals = 18;
    // const trans_amount = 15;
    // const amount1 = BigNumber.from(trans_amount).mul(BigNumber.from(10).pow(decimals));

    let VRFCoordinatorAddress;
    let subscriptionId;
    const accounts = await hre.ethers.getSigners();
    const signer = accounts[0];
    // log(signer); - signer Object will be logged which is our metamsk connected account
    const keyHash = networkConfig[chainId]['keyHash'];
    let vrfCoordinator;
    let RandomSVG;

    // If we are deploying on a localhardhat chain than it doesn't have vrf contrcat or other outsider contract
    // So we have to import those contrcat in test folder in contrcat folder
    // Then we have to deploy them and get their addresses
    // But if we are deploying on real chain then we have to use the real ones
    if (chainId == 31337) {
        // It means we are on local chain. so, 00 deploy scipt will run which will deploy the necessary contrcat
        // We can get the mock contrcat deployed by get method
        let VRFCoordinator = await get("VRFCoordinatorV2Mock");
        VRFCoordinatorAddress = VRFCoordinator.address;
        vrfCoordinator = await ethers.getContractAt("VRFCoordinatorV2Mock", VRFCoordinatorAddress, signer);
        // In case of mock we have to create subscription and fund it in order to interact with vrfCoordinator
        let createSubscription = await vrfCoordinator.createSubscription();
        let receipt1 = await createSubscription.wait(1);
        // Get the subscription id from log or event
        subscriptionId = receipt1.events[0].topics[1]
        let fundtx = await vrfCoordinator.fundSubscription(subscriptionId, 1000000000);
        await fundtx.wait(1);
        const args = [VRFCoordinatorAddress, subscriptionId, keyHash];
        // Only have to deploy in case of local network coz in case of real network 03 script will deploy it
        log('------------------------');
         RandomSVG = await deploy("RandomSVG", {
            from: deployer,
            log: true,
            args: args
        });
        log(`Yoy have deployed an NFT contrcat to ${RandomSVG.address}`);
        const networkName = networkConfig[chainId]['name'];
        // If constructor is taking arguments than we have to provide them during verification
        log(`Verify with: \n npx hardhat verify --network ${networkName} ${RandomSVG.address} ${args.toString().replace(/,/g, " ")}`);
    } else {
        // It means we have deployed to real chain-
        // So getting it by get method
        RandomSVG = await get("RandomSVG");

    }





    // Now we want to interact with contrcat so, we need to make instance of contract
    const RandomSVGContrcat = await ethers.getContractFactory("RandomSVG");

    const randomSVG = new ethers.Contract(RandomSVG.address, RandomSVGContrcat.interface, signer);
    let creation_tx = await randomSVG.create({ gasLimit: 300000 });
    let receipt2 = await creation_tx.wait(1);
    // const event = receipt2.events.find(event => event.event === 'RandomWordsRequested');
    // const [reqId,,,,,,, sender] = event;
    let reqId = receipt2.events[1].topics[1];
    let tokenId = receipt2.events[1].topics[2];
    // Function create emits the event ehuch has token id- it is 2nd evvent as chainlink contract emits other3 evevnts before throwing it
    
    log(`You've made your NFT! This is tokenNumber ${tokenId.toString()}`);
    log(`Let's wait for Chainlink node to respond`);
    // In case of real chain everything will work but incase of localhost you have to call the vrf callbackfunction manually
    if(chainId != 31337) {
        // Real Chain
        // Here vrf itself will make a call to fulfillrandomness function so we dont have to call that function manually
        // waiting for few seconds for Chainlink to respond
        await new Promise(r => setTimeout(r, 180000));
        log(`Now let's finish the mint...`);
        let finish_tx = await randomSVG.finishMint(tokenId, { gasLimit: 2000000 });
        await finish_tx.wait(1);
        log(`You can view the tokenURI here: ${await randomSVG.tokenURI(tokenId)}`);

    } else {
        // Local Chain
        // If we see the vrfCoordinatorMock contract it uses callBackWithRandomness function
        // Pramaeter- req id from log, random number and consumer address
        let vrf_tx = await vrfCoordinator.fulfillRandomWords(reqId, randomSVG.address);
        await vrf_tx.wait(1);
        log(`Now let's finish the mint`);
        // log(randomSVG.address == RandomSVG.address); //true
        let finish_tx = await randomSVG.finishMint(tokenId, {gasLimit: 2000000 });
        await finish_tx.wait(1);
        log(`You can view the tokenUri here: ${await randomSVG.tokenURI(tokenId)}`);

    }




    
}

module.exports.tags = ["all", "rsvg"];