const fs = require("fs")
let {networkConfig} = require('../helper-hardhat-config.js')

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    // Here deploy knows all of the contracts from contrcats folder
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = await getChainId()

    log("_________________")
    // Here deploy will access the SVGNFT contact from contractsfolder
    const SVGNFT = await deploy("SVGNFT", {
        from: deployer,
        log: true
    })
    log(`Yoy have deployed an NFT contrcat to ${SVGNFT.address}`)
    // reading svg file
    let filePath = "./img/triangle.svg"
    let svg = fs.readFileSync(filePath, { encoding: "utf8" })
    
    const svgNFTContract = await ethers.getContractFactory("SVGNFT")
    const accounts = await hre.ethers.getSigners()
    // In case of real chain, signer will be our metamsk connected account-whose privatekey we have given in env file
    const signer = accounts[0]
    const svgNFT = new ethers.Contract(SVGNFT.address, svgNFTContract.interface, signer)
    const networkName = networkConfig[chainId]['name']
    log(`Verify with: \n npx hardhat verify --network ${networkName} ${svgNFT.address}`)

    let txRespone = await svgNFT.create(svg)
    let receipt = await txRespone.wait(1);
    log(`You have made an NFT!`)
    log(`You can view the tokenURI here ${await svgNFT.tokenURI(0)}`)

}