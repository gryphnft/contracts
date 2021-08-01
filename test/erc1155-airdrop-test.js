const { expect } = require("chai");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

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

function hashToken(account, tokenId, quantity) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(
      ['address', 'uint256', 'uint256'],
      [account, tokenId, quantity]
    ).slice(2),
    'hex'
  )
}

async function dropAndRedeem(contract) {
  //get the signers
  const signers = await ethers.getSigners()

  //make the tree
  const merkleTree1 = new MerkleTree(
    [
      hashToken(signers[1].address, 1, 10),
      hashToken(signers[2].address, 1, 20)
    ],
    keccak256,
    { sortPairs: true }
  );

  const merkleTree2 = new MerkleTree(
    [
      hashToken(signers[1].address, 2, 30),
      hashToken(signers[2].address, 2, 40)
    ],
    keccak256,
    { sortPairs: true }
  );

  //make the drops
  await contract.drop(1, merkleTree1.getHexRoot())
  await contract.drop(2, merkleTree2.getHexRoot())

  await contract.redeem(signers[1].address, 1, 10, merkleTree1.getHexProof(
    hashToken(signers[1].address, 1, 10)
  ), 0x0)
  await contract.redeem(signers[2].address, 1, 20, merkleTree1.getHexProof(
    hashToken(signers[2].address, 1, 20)
  ), 0x0)
  await contract.redeem(signers[1].address, 2, 30, merkleTree2.getHexProof(
    hashToken(signers[1].address, 2, 30)
  ), 0x0)
  await contract.redeem(signers[2].address, 2, 40, merkleTree2.getHexProof(
    hashToken(signers[2].address, 2, 40)
  ), 0x0)
}

describe('ERC1155 NFT Air Drop Tests', function () {
  it('Should allow redeeming of air drops', async function () {
    //now build the accounts
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC1155AirDrop',
      //this is the game URL ?
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    await dropAndRedeem(owner.contract)

    expect(await owner.contract.balanceOf(recipient1.signer.address, 1)).to.equal(10)
    expect(await owner.contract.balanceOf(recipient2.signer.address, 1)).to.equal(20)
    expect(await owner.contract.balanceOf(recipient1.signer.address, 2)).to.equal(30)
    expect(await owner.contract.balanceOf(recipient2.signer.address, 2)).to.equal(40)
  })

  it('Should list and delist token', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC1155AirDrop',
      //this is the game URL ?
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    await dropAndRedeem(owner.contract)

    //let the owner try to list the token for sale
    let error = false
    try {
      await owner.contract.list(1, 500000, 1)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to list the token for sale
    // where amount is in wei
    await recipient.contract.list(
      //token id
      1,
      //amount
      500000,
      //quantity
      10
    )
    let listing = await recipient.contract.getListing(recipient.signer.address, 1)
    expect(listing.owner).to.equal(recipient.signer.address)
    expect(listing.amount).to.equal(500000)
    expect(listing.quantity).to.equal(10)

    //let the owner try to delist the token sale
    error = false
    try {
      await owner.contract.delist(1)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to delist
    await recipient.contract.delist(1)
    listing = await recipient.contract.getListing(recipient.signer.address, 1)
    expect(listing.amount).to.equal(0)
    expect(listing.quantity).to.equal(0)

    //even non existent tokens are 0
    listing = await recipient.contract.getListing(recipient.signer.address, 100)
    expect(listing.amount).to.equal(0)
    expect(listing.quantity).to.equal(0)
  })

  it('Should list and exchange token', async function () {
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC1155AirDrop',
      //this is the game URL ?
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    await dropAndRedeem(owner.contract)

    const oneEther = ethers.utils.parseEther('1.0')
    const sixEther = ethers.utils.parseEther('2.0')
    const nineEther = ethers.utils.parseEther('9.0')

    //let the recipient try to list the token for sale
    // where amount is in wei
    await recipient1.contract.list(
      //token id
      1,
      //amount
      oneEther,
      //quantity
      10
    )
    let listing = await recipient1.contract.getListing(recipient1.signer.address, 1)
    expect(listing.owner).to.equal(recipient1.signer.address)
    expect(listing.amount).to.equal(oneEther)
    expect(listing.quantity).to.equal(10)

    //let the recipient try to buy it for the wrong amount
    let error = false
    try {
      await recipient2.contract.exchange(recipient1.signer.address, 1, 1000, 0x0, { value: twoEther })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to buy it for a higher quantity
    error = false
    try {
      await recipient2.contract.exchange(recipient1.signer.address, 1, 2000, 0x0, { value: oneEther })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to buy it for the right amount and quantity
    await recipient2.contract.exchange(
      //recipient
      recipient1.signer.address,
      //token id
      1,
      //quantity
      1,
      //data?
      0x0,
      //embeded value
      { value: oneEther }
    )

    listing = await recipient1.contract.getListing(recipient1.signer.address, 1)
    expect(listing.owner).to.equal(recipient1.signer.address)
    expect(listing.amount).to.equal(oneEther)
    expect(listing.quantity).to.equal(9)

    await recipient2.contract.exchange(recipient1.signer.address, 1, 9, 0x0, { value: nineEther })
    listing = await recipient1.contract.getListing(recipient1.signer.address, 1)
    expect(listing.amount).to.equal(0)
    expect(listing.quantity).to.equal(0)

    //let the recipient try to buy it for the right amount again
    error = false
    try {
      await recipient2.contract.exchange(recipient1.signer.address, 1, 1, 0x0, { value: oneEther })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
  })

  it('Should add royalties', async function () {
    const [owner, recipient1, recipient2, recipient3] = await getAccounts(
      4,
      'ERC1155AirDrop',
      //this is the game URL ?
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    //set fee 1 (200 is 2.00%)
    await owner.contract.setFee(1, recipient1.signer.address, 200)
    expect(await owner.contract.getFee(1, recipient1.signer.address)).to.equal(200)

    //set fee 2 (100 is 1.00%)
    await owner.contract.setFee(1, recipient2.signer.address, 100)
    expect(await owner.contract.getFee(1, recipient2.signer.address)).to.equal(100)
    //total should now be 3.00%
    expect(await owner.contract.getTotalFees(1)).to.equal(300)

    //try to over allocate
    let error = false
    try {
      await owner.contract.setFee(1, recipient3.signer.address, 10000)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //set fee 3 (300 is 3.00%)
    await owner.contract.setFee(1, recipient3.signer.address, 300)
    expect(await owner.contract.getFee(1, recipient3.signer.address)).to.equal(300)
    //total should now be 6.00%
    expect(await owner.contract.getTotalFees(1)).to.equal(600)

    //reset fee 1 (2000 is 20.00%)
    await owner.contract.setFee(1, recipient1.signer.address, 2000)
    expect(await owner.contract.getFee(1, recipient1.signer.address)).to.equal(2000)
    //total should now be 24.00%
    expect(await owner.contract.getTotalFees(1)).to.equal(2400)

    //remove fee 2
    await owner.contract.removeFee(1, recipient2.signer.address)
    //total should now be 23.00%
    expect(await owner.contract.getTotalFees(1)).to.equal(2300)

    //remove fee of someone that hasn't been entered
    error = false
    try {
      await owner.contract.removeFee(1, owner.signer.address)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
  })

  it('Should list and exchange token with royalties', async function () {
    const [contractOwner, tokenOwner, tokenOwner2, creator, manager, buyer] = await getAccounts(
      6,
      'ERC1155AirDrop',
      //this is the game URL ?
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    //----------------------------------------//
    // These are the current balance states
    creator.state = parseFloat(
      ethers.utils.formatEther(await creator.signer.getBalance())
    )

    manager.state = parseFloat(
      ethers.utils.formatEther(await manager.signer.getBalance())
    )

    tokenOwner.state = parseFloat(
      ethers.utils.formatEther(await tokenOwner.signer.getBalance())
    )

    buyer.state = parseFloat(
      ethers.utils.formatEther(await buyer.signer.getBalance())
    )

    //----------------------------------------//
    // This is the fee setup
    //The creator wants 20% (2000 is 20.00%)
    await contractOwner.contract.setFee(1, creator.signer.address, 2000)
    expect(
      await contractOwner.contract.getFee(1, creator.signer.address)
    ).to.equal(2000)

    //The manager wants 10% (1000 is 10.00%)
    await contractOwner.contract.setFee(1, manager.signer.address, 1000)
    expect(
      await contractOwner.contract.getFee(1, manager.signer.address)
    ).to.equal(1000)

    //total fees should now be 30.00%
    expect(await contractOwner.contract.getTotalFees(1)).to.equal(3000)

    //----------------------------------------//
    // This is the minting
    await dropAndRedeem(contractOwner.contract)

    //----------------------------------------//
    // This is the listing
    const listedAmount = ethers.utils.parseEther('10.0')
    //the token owner can only list their token for sale
    await tokenOwner.contract.list(1, listedAmount, 10)

    let listing = await tokenOwner.contract.getListing(tokenOwner.signer.address, 1)
    expect(listing.owner).to.equal(tokenOwner.signer.address)
    expect(listing.amount).to.equal(listedAmount)
    expect(listing.quantity).to.equal(10)
    //update token owner state
    tokenOwner.state = parseFloat(
      ethers.utils.formatEther(await tokenOwner.signer.getBalance())
    )

    //----------------------------------------//
    // This is the exchange
    //the buyer will purchase it for the right amount
    await buyer.contract.exchange(tokenOwner.signer.address, 1, 2, 0x0, {
      value: ethers.utils.parseEther('20.0')
    })

    //----------------------------------------//
    // This is the test
    expect(
      ethers.utils.formatEther(
        await ethers.provider.getBalance(contractOwner.contract.address)
      )
    ).to.equal('0.0')

    expect(parseFloat(
      ethers.utils.formatEther(await creator.signer.getBalance())
    ) - parseFloat(creator.state)).to.equal(4)

    expect(parseFloat(
      ethers.utils.formatEther(await manager.signer.getBalance())
    ) - parseFloat(manager.state)).to.equal(2)

    expect(parseFloat(
      ethers.utils.formatEther(await tokenOwner.signer.getBalance())
    ) - parseFloat(tokenOwner.state)).to.equal(14)

    expect(
      Math.ceil(
        parseFloat(
          ethers.utils.formatEther(await buyer.signer.getBalance())
        ) - parseFloat(buyer.state)
      )
    ).to.equal(-20)
  })
})
