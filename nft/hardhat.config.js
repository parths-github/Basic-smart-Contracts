require("@nomiclabs/hardhat-waffle");
// To read from .env file
require("dotenv").config({ path: ".env"});



// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",

  // 1. Have to define which network to get deploy on: For that we create our own node on alchemy and provide its url here
  // One of the config option is network in config file
  networks: {
    rinkeby: {
      // the url is of node to which our transaction first go and then it will broadcast it to the frest of the network
      // While using remix we don't have to worry about it as metamask have the url of node that will listen to our transaction
      /* 2 data to be provide but we can't provide them directly as after 
      pusing it to github anyone can see our private key and our node's url. So store them in .env file. 
      */
     url: process.env.ALCHEMY_API_KEY_URL,
     accounts: [process.env.PRIVATE_KEY],
    },
  },

  // 2.Define which account to use for deployement
};
