
// const { BigNumber } = require("ethers")
// const decimals = 18;
// const trans_amount = 1500;
// const amount1 = BigNumber.from(trans_amount).mul(BigNumber.from(10).pow(decimals));
// const amount2 = BigNumber.from(25000).mul(BigNumber.from(10).pow(decimals));


// Script to deploy the mock contrcat in case of deploying on local Chain

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const { deploy, log} = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();
    // Only run if we deployed contrcat to local chain
    if (chainId == 31337) {
        log(`Local network detected! Deploying Mocks...`)
        const LinkToken = await deploy("LinkToken", {
            from: deployer,
            log: true
        })
        const VRFCoordinator = await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: [10, 5]
        })
        log(`Mocks Deployed`)
    }
}

module.exports.tags = ["all", "rsvg", "svg"]