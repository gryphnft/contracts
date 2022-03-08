//to run this on testnet:
// $ npx hardhat run scripts/blacklist-gns.js

const hardhat = require('hardhat')
const blacklist = require('../data/blacklist.json')

async function attach(name, address) {
  const Contract = await hardhat.ethers.getContractFactory(name)
  return await Contract.attach(address)
}

async function main() {
  const network = hardhat.config.networks[hardhat.config.defaultNetwork]
  const provider = new hardhat.ethers.providers.JsonRpcProvider(network.url)
  const owner = await attach('GryphNamespaces', network.contracts.namespaces)

  let buffer = []
  for (let i = 0; i < blacklist.length; i++) {
    buffer.push(blacklist[i])
    if (buffer.length == 10) {
      const gasPrice = (await provider.getGasPrice()).mul(30).toString(); //wei
      const GgasPrice = Math.ceil(parseInt(gasPrice) / 1000000000)
      const gasLimit = Math.floor(GgasPrice * 21000)

      console.log('Blacklisting', buffer)

      const queue = await owner.blacklist(buffer, { gasPrice, gasLimit })
      const tx = await queue.wait()
      buffer = []

      console.log(tx)
    }
  }

  if (buffer.length) {
    const gasPrice = (await provider.getGasPrice()).mul(30).toString(); //wei
    const GgasPrice = Math.ceil(parseInt(gasPrice) / 1000000000)
    const gasLimit = Math.floor(GgasPrice * 21000)

    console.log('Blacklisting', buffer)

    const queue = await owner.blacklist(buffer, { gasPrice, gasLimit })
    const tx = await queue.wait()
    buffer = []

    console.log(tx)
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});
