//to run this on testnet:
// $ npx hardhat run scripts/deploy-gns.js

const hardhat = require('hardhat')
const blacklist = require('../data/blacklist.json')

async function attach(name, address) {
  const Contract = await hardhat.ethers.getContractFactory(name)
  return await Contract.attach(address)
}

async function main() {
  await hre.run('compile')
  const NFT = await hardhat.ethers.getContractFactory('GryphNamespaces')
  const nft = await NFT.deploy()
  await nft.deployed()
  console.log('NFT contract deployed to (update .env):', nft.address)
  console.log('npx hardhat verify --network', hardhat.config.defaultNetwork, nft.address)

  const network = hardhat.config.networks[hardhat.config.defaultNetwork]
  const provider = new hardhat.ethers.providers.JsonRpcProvider(network.url)
  const owner = await attach('GryphNamespaces', network.contracts[0])

  let buffer = []
  for (let i = 0; i < blacklist.length; i++) {
    buffer.push(blacklist[i])
    if (buffer.length == 20) {
      const gasPrice = (await provider.getGasPrice()).mul(5).toString(); //wei
      const GgasPrice = Math.ceil(parseInt(gasPrice) / 1000000000)
      const gasLimit = Math.floor(GgasPrice * 21000)

      await owner.blacklist(buffer, { gasPrice, gasLimit })
      buffer = []
    }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});

//$ npx hardhat verify --network testnet 
//$ npx hardhat verify --network mainnet 
