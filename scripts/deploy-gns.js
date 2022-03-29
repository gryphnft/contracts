//to run this on testnet:
// $ npx hardhat run scripts/deploy-gns.js

const hardhat = require('hardhat')

const uri = 'https://ipfs.io/ipfs/bafkreicw32mefimobvabviirb7rao45r3kpy5zdudiputyubcmp2gag4xa'

async function deploy(name, ...params) {
  //deploy the contract
  const ContractFactory = await ethers.getContractFactory(name)
  const contract = await ContractFactory.deploy(...params)
  await contract.deployed()

  return contract
}

async function main() {
  await hre.run('compile')
  const registry = await deploy('GryphNamespaceRegistry', uri)
  const sale = await deploy('GryphNamespaceSale', registry.address)

  console.log('Registry contract deployed to (update .env):', registry.address)
  console.log('npx hardhat verify --network', hardhat.config.defaultNetwork, registry.address, `"${uri}"`)
  console.log('-------------------------------')
  console.log('Sale contract deployed to (update .env):', sale.address)
  console.log('npx hardhat verify --network', hardhat.config.defaultNetwork, sale.address, `"${registry.address}"`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});
