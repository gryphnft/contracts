//to run this on testnet:
// $ npx hardhat run scripts/deploy-gns.js

const hardhat = require('hardhat')

async function main() {
  await hre.run('compile')
  const network = hardhat.config.networks[hardhat.config.defaultNetwork]
  const NFT = await hardhat.ethers.getContractFactory('GryphNamespaces')
  const nft = await hardhat.upgrades.UpgradeProxy(network.contracts.namespaces, NFT)
  await nft.deployed()
  console.log('Proxy contract updated to (update .env):', nft.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});

//$ npx hardhat verify --network testnet 0xCFe522301C7246401387003156dFb7cd4826Bd3b "https://ipfs.io/ipfs/bafkreicw32mefimobvabviirb7rao45r3kpy5zdudiputyubcmp2gag4xa"
//$ npx hardhat verify --network mainnet 
