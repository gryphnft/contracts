const { expect } = require("chai");

async function getAccounts(max, name, ...params) {
  //get the signers
  const signers = await ethers.getSigners()
  //deploy the contract
  const ContractFactory = await ethers.getContractFactory(name)
  const contract = await ContractFactory.deploy(...params)
  await contract.deployed()
  //setup the first account
  const accounts = [{ signer: signers[0], contract: contract }]

  for (let i = 1; i < max; i++) {
    const Contract = await ethers.getContractFactory(name, signers[i])
    accounts.push({
      signer: await signers[i],
      contract: await Contract.attach(contract.address)
    })
  }

  return accounts
}

describe('ERC1155 NFT Preset Tests', function () {
  it('Should deploy contract and mint', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC1155PresetVanilla',
      //this is the game URL ?
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    //mint a token and transfer it to the recipient
    await owner.contract.mint(owner.signer.address, 1, 1000, 0x0)
    expect(await owner.contract.balanceOf(owner.signer.address, 1)).to.equal(1000)

    await owner.contract.safeTransferFrom(
      owner.signer.address,
      recipient.signer.address,
      1,
      10,
      0x0
    )

    expect(await owner.contract.balanceOf(owner.signer.address, 1)).to.equal(990)
    expect(await owner.contract.balanceOf(recipient.signer.address, 1)).to.equal(10)

    //NOTE: you save 50% on costs when you mint batch
    await owner.contract.mintBatch(
      owner.signer.address,
      //token ids
      [2, 3, 4, 5, 6, 7, 8, 9, 10],
      //amounts per token id
      [2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000],
      0x0
    )

    expect(await owner.contract.balanceOf(owner.signer.address, 2)).to.equal(2000)
    expect(await owner.contract.balanceOf(owner.signer.address, 3)).to.equal(3000)
    expect(await owner.contract.balanceOf(owner.signer.address, 4)).to.equal(4000)

    await owner.contract.safeTransferFrom(
      owner.signer.address,
      recipient.signer.address,
      2,
      20,
      0x0
    )

    expect(await owner.contract.balanceOf(owner.signer.address, 2)).to.equal(1980)
    expect(await owner.contract.balanceOf(recipient.signer.address, 2)).to.equal(20)
  })
})
