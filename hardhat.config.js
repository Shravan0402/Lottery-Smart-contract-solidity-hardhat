require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy")
require('dotenv').config()
/** @type import('hardhat/config').HardhatUserConfig */
RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL
PRIVATE_RINKEBY_KEY = process.env.PRIVATE_RINKEBY_KEY
module.exports = {
  defaultNetwork: "hardhat",
  solidity: "0.8.9",
  networks:{
    hardhat:{
      chainId: 31337,
      blockConfirmations:1,
    },
    rinkeby:{
      chainId:4,
      blockConfirmations:6,
      url: RINKEBY_RPC_URL,
      accounts:[PRIVATE_RINKEBY_KEY]
    }
  },
  namedAccounts:{
    deployer:{
      default : 0
    },
    player:{
      default :1
    }
  }
};
