//to run this on testnet:
// $ npx hardhat run scripts/deploy.js

const hardhat = require('hardhat')

async function deploy(name, ...params) {
  //deploy the contract
  const ContractFactory = await ethers.getContractFactory(name)
  const contract = await ContractFactory.deploy(...params)
  await contract.deployed()

  return contract
}

async function main() {
  await hre.run('compile')

  const token = await deploy('GryphToken')
  const treasury = await deploy('GryphTreasury')
  const economy = await deploy('GryphEconomy', token.address, treasury.address)
  const vesting = await deploy('GryphVesting', token.address, treasury.address, economy.address)

  console.log('Token contract deployed to (update .env):', token.address)
  console.log('npx hardhat verify --network', process.env.BLOCKCHAIN_NETWORK, token.address)
  console.log('----------')
  console.log('Treasury contract deployed to (update .env):', treasury.address)
  console.log('npx hardhat verify --network', process.env.BLOCKCHAIN_NETWORK, treasury.address)
  console.log('----------')
  console.log('Economy contract deployed to (update .env):', economy.address)
  console.log('npx hardhat verify --network', process.env.BLOCKCHAIN_NETWORK, economy.address, `"${token.address}"`, `"${treasury.address}"`)
  console.log('----------')
  console.log('Vesting contract deployed to (update .env):', vesting.address)
  console.log('npx hardhat verify --network', process.env.BLOCKCHAIN_NETWORK, vesting.address, `"${token.address}"`, `"${treasury.address}"`, `"${economy.address}"`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});
