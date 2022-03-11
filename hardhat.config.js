require('@openzeppelin/hardhat-upgrades');
require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-waffle');
require('hardhat-contract-sizer');
require('hardhat-gas-reporter');
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: process.env.BLOCKCHAIN_NETWORK,
  networks: {
    hardhat: {
      chainId: 1337,
      mining: {
        //set this to false if you want localhost to mimick a real blockchain
        auto: true,
        interval: 5000
      }
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      accounts: [process.env.BLOCKCHAIN_LOCALHOST_PRIVATE_KEY],
      contracts: {
        namespaces: process.env.BLOCKCHAIN_LOCALHOST_NAMESPACE_ADDRESS,
        token: process.env.BLOCKCHAIN_LOCALHOST_TOKEN_ADDRESS,
        treasury: process.env.BLOCKCHAIN_LOCALHOST_TREASURY_ADDRESS,
        economy: process.env.BLOCKCHAIN_LOCALHOST_ECONOMY_ADDRESS,
        vesting: process.env.BLOCKCHAIN_LOCALHOST_VESTING_ADDRESS
      }
    },
    testnet: {
      url: 'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      accounts: [process.env.BLOCKCHAIN_TESTNET_PRIVATE_KEY],
      contracts: {
        namespaces: process.env.BLOCKCHAIN_TESTNET_NAMESPACE_ADDRESS,
        token: process.env.BLOCKCHAIN_TESTNET_TOKEN_ADDRESS,
        treasury: process.env.BLOCKCHAIN_TESTNET_TREASURY_ADDRESS,
        economy: process.env.BLOCKCHAIN_TESTNET_ECONOMY_ADDRESS,
        vesting: process.env.BLOCKCHAIN_TESTNET_VESTING_ADDRESS
      }
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      accounts: [process.env.BLOCKCHAIN_MAINNET_PRIVATE_KEY],
      contracts: {
        namespaces: process.env.BLOCKCHAIN_MAINNET_NAMESPACE_ADDRESS,
        token: process.env.BLOCKCHAIN_MAINNET_TOKEN_ADDRESS,
        treasury: process.env.BLOCKCHAIN_MAINNET_TREASURY_ADDRESS,
        economy: process.env.BLOCKCHAIN_MAINNET_ECONOMY_ADDRESS,
        vesting: process.env.BLOCKCHAIN_MAINNET_VESTING_ADDRESS
      }
    },
  },
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: './contracts',
    tests: './tests',
    cache: './cache',
    artifacts: './artifacts'
  },
  mocha: {
    timeout: 20000
  },
  gasReporter: {
    currency: 'USD',
    coinmarketcap: process.env.BLOCKCHAIN_CMC_KEY,
    gasPrice: 200
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.BLOCKCHAIN_SCANNER_KEY
  },
  contractSizer: {
    //see: https://www.npmjs.com/package/hardhat-contract-sizer
    runOnCompile: true
  }
};