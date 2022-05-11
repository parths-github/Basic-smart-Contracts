// This script is to deploy RandomSVG on real chain-- we could have done it in 02_deploy_randomSVG.js script but we have to provide the contrcat address to chainlink vrfCoordinator subscription in order to interact with vrf
// So we are deploying it here and will interact with it in 02 script
const { networkConfig } = require("../helper-hardhat-config");


module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const {deploy, log, get} = deployments;
    // Will fetch the deployer from hardhat.config.js - accounts
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();

    // Get variables from helper-hardhat
    // Thes variables are required for constructor of vrfCoordinator
    const VRFCoordinatorAddress = networkConfig[chainId]['VRFCoordinatorAddress'];
    const keyHash = networkConfig[chainId]['keyHash'];
    const subscriptionId = networkConfig[chainId]['subscriptionId'];
    log(VRFCoordinatorAddress, subscriptionId, keyHash);
    const args = [VRFCoordinatorAddress, subscriptionId, keyHash];
    // deploy will fetch the contract named RandomSVG
    const RandomSVG = await deploy("RandomSVG", {
        from: deployer,
        log: true,
        args: args
    })
    log(`Yoy have deployed an NFT contrcat to ${RandomSVG.address}`);


    // To get the contrcat verify on etherscan
    const networkName = networkConfig[chainId]['name'];
    log(`Verify with: \n npx hardhat verify --network ${networkName} ${RandomSVG.address} ${args.toString().replace(/,/g, " ")}`);
}
// hh deploy --network rinkeby --tags testnet- will only run this script and will deploy contrcat to rinkeby
module.exports.tags = ["all", "testnet"];