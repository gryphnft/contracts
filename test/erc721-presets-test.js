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

function hashToken(tokenId, account) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(
      ['uint256', 'address'],
      [tokenId, account]
    ).slice(2),
    'hex'
  )
}

describe('ERC721 Preset Tests', function () {
  it('ERC721PresetVanilla: Should deploy contract and mint', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC721PresetVanilla',
      'Political Art',
      'POLYART'
    )

    //mint a token and transfer it to the recipient
    await owner.contract.mint(recipient.signer.address)

    expect(await owner.contract.ownerOf(1)).to.equal(recipient.signer.address)
  })

  it('ERC721PresetZeppelin: Should mint and burn token', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC721PresetZeppelin',
      'Political Art',
      'POLYART'
    )

    //mint a token and transfer it to the recipient
    await owner.contract.mint(
      recipient.signer.address,
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    expect(await owner.contract.ownerOf(1)).to.equal(recipient.signer.address)
    expect(await owner.contract.tokenURI(1)).to.equal(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    //let the owner try to burn it
    let error = false
    try {
      await owner.contract.burn(1)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to burn it
    await recipient.contract.burn(1)

    error = false
    try {
      await nft.ownerOf(1)
    } catch (e) {
      error = true
    }

    expect(error).to.equal(true)
  })

  it('ERC721PresetContractURI: Should add contract URI', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC721PresetContractURI',
      'Political Art',
      'POLYART',
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )

    //mint a token and transfer it to the recipient
    await owner.contract.mint(recipient.signer.address)

    expect(await owner.contract.ownerOf(1)).to.equal(recipient.signer.address)
    expect(await owner.contract.contractURI()).to.equal(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF'
    )
  })

  it('ERC721PresetMaxQuantity: Should have a max quantity when minting', async function () {
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC721PresetMaxQuantity',
      'Political Art',
      'POLYART',
      2
    )

    //mint 1
    await owner.contract.mint(recipient1.signer.address)
    expect(await owner.contract.ownerOf(1)).to.equal(recipient1.signer.address)

    //mint 2
    await owner.contract.mint(recipient2.signer.address)
    expect(await owner.contract.ownerOf(2)).to.equal(recipient2.signer.address)

    //should error
    let error = false
    try {
      //mint 3
      await owner.contract.mint(recipient1.signer.address)
    } catch (e) {
      error = true
    }

    expect(error).to.equal(true)
  })

  it('ERC721PresetPreMint: Should pre-mint tokens on deploy', async function () {
    //we need to get the signers to add their address on contruction...
    const signers = await ethers.getSigners()
    //now build the accounts
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC721PresetPreMint',
      'Political Art',
      'POLYART',
      [
        signers[1].address,
        signers[2].address
      ]
    )

    expect(await owner.contract.ownerOf(1)).to.equal(recipient1.signer.address)
    expect(await owner.contract.ownerOf(2)).to.equal(recipient2.signer.address)
  })

  it('ERC721PresetAirDrop: Should allow redeeming of air drops', async function () {
    //we need to get the signers to add their address on contruction...
    const signers = await ethers.getSigners()

    //make the tree
    const merkleTree = new MerkleTree(
      [
        hashToken(1, signers[1].address),
        hashToken(2, signers[2].address)
      ],
      keccak256,
      { sortPairs: true }
    );

    //now build the accounts
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC721PresetAirDrop',
      'Political Art',
      'POLYART',
      merkleTree.getHexRoot()
    )

    await owner.contract.redeem(
      1,
      recipient1.signer.address,
      merkleTree.getHexProof(
        hashToken(1, recipient1.signer.address)
      )
    )

    expect(await owner.contract.ownerOf(1)).to.equal(recipient1.signer.address)

    await owner.contract.redeem(
      2,
      recipient2.signer.address,
      merkleTree.getHexProof(
        hashToken(2, recipient2.signer.address)
      )
    )

    expect(await owner.contract.ownerOf(2)).to.equal(recipient2.signer.address)
  })

  it('ERC721PresetListable: Should list and delist token', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC721PresetListable',
      'Political Art',
      'POLYART'
    )

    //mint and transfer
    await owner.contract.mint(recipient.signer.address)

    //let the owner try to list the token for sale
    let error = false
    try {
      await owner.contract.list(1, 500000)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to list the token for sale
    // where amount is in wei
    await recipient.contract.list(1, 500000)
    const listing1 = await recipient.contract.getListing(1)
    expect(listing1).to.equal(500000)

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
    const listing2 = await recipient.contract.getListing(1)
    expect(listing2).to.equal(0)

    //even non existent tokens are 0
    const listing3 = await recipient.contract.getListing(100)
    expect(listing3).to.equal(0)
  })

  it('ERC721PresetExchangable: Should list and exchange token', async function () {
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC721PresetExchangable',
      'Political Art',
      'POLYART'
    )

    //mint and transfer
    await owner.contract.mint(recipient1.signer.address)

    const oneEther = ethers.utils.parseEther('1.0')
    const sixEther = ethers.utils.parseEther('2.0')

    //let the recipient try to list the token for sale
    await recipient1.contract.list(1, oneEther)
    const listing1 = await recipient1.contract.getListing(1)
    expect(listing1).to.equal(oneEther)

    //let the recipient try to buy it for the wrong amount
    let error = false
    try {
      await recipient2.contract.exchange(1, { value: twoEther })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to buy it for the right amount
    await recipient2.contract.exchange(1, { value: oneEther })

    //let the recipient try to buy it for the right amount again
    error = false
    try {
      await recipient2.contract.exchange(1, { value: oneEther })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
  })

  it('ERC721PresetTransferFees: Should add royalties', async function () {
    const [owner, recipient1, recipient2, recipient3] = await getAccounts(
      4,
      'ERC721PresetTransferFees',
      'Political Art',
      'POLYART'
    )

    //set fee 1 (200 is 2.00%)
    await owner.contract.setFee(recipient1.signer.address, 200)
    expect(await owner.contract.fees(recipient1.signer.address)).to.equal(200)

    //set fee 2 (100 is 1.00%)
    await owner.contract.setFee(recipient2.signer.address, 100)
    expect(await owner.contract.fees(recipient2.signer.address)).to.equal(100)
    //total should now be 3.00%
    expect(await owner.contract.totalFees()).to.equal(300)

    //try to over allocate
    let error = false
    try {
      await owner.contract.setFee(recipient3.signer.address, 10000)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //set fee 3 (300 is 3.00%)
    await owner.contract.setFee(recipient3.signer.address, 300)
    expect(await owner.contract.fees(recipient3.signer.address)).to.equal(300)
    //total should now be 6.00%
    expect(await owner.contract.totalFees()).to.equal(600)

    //reset fee 1 (2000 is 20.00%)
    await owner.contract.setFee(recipient1.signer.address, 2000)
    expect(await owner.contract.fees(recipient1.signer.address)).to.equal(2000)
    //total should now be 24.00%
    expect(await owner.contract.totalFees()).to.equal(2400)

    //remove fee 2
    await owner.contract.removeFee(recipient2.signer.address)
    //total should now be 23.00%
    expect(await owner.contract.totalFees()).to.equal(2300)

    //remove fee of someone that hasn't been entered
    error = false
    try {
      await owner.contract.removeFee(owner.signer.address)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
  })

  it('ERC721PresetExchangableFees: Should list and exchange token with royalties', async function () {
    const [contractOwner, creator, manager, tokenOwner, buyer] = await getAccounts(
      5,
      'ERC721PresetExchangableFees',
      'Political Art',
      'POLYART'
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
    await contractOwner.contract.setFee(creator.signer.address, 2000)
    expect(
      await contractOwner.contract.fees(creator.signer.address)
    ).to.equal(2000)

    //The manager wants 10% (1000 is 10.00%)
    await contractOwner.contract.setFee(manager.signer.address, 1000)
    expect(
      await contractOwner.contract.fees(manager.signer.address)
    ).to.equal(1000)

    //total fees should now be 30.00%
    expect(await contractOwner.contract.totalFees()).to.equal(3000)

    //----------------------------------------//
    // This is the minting
    //fast forward ... (go straight to the token owner)
    await contractOwner.contract.mint(tokenOwner.signer.address)

    //----------------------------------------//
    // This is the listing
    const listedAmount = ethers.utils.parseEther('10.0')
    //the token owner can only list their token for sale
    await tokenOwner.contract.list(1, listedAmount)
    const listing1 = await tokenOwner.contract.getListing(1)
    expect(listing1).to.equal(listedAmount)
    //update token owner state
    tokenOwner.state = parseFloat(
      ethers.utils.formatEther(await tokenOwner.signer.getBalance())
    )

    //----------------------------------------//
    // This is the exchange
    //the buyer will purchase it for the right amount
    await buyer.contract.exchange(1, { value: listedAmount })

    //----------------------------------------//
    // This is the test
    expect(
      ethers.utils.formatEther(
        await ethers.provider.getBalance(contractOwner.contract.address)
      )
    ).to.equal('0.0')

    expect(parseFloat(
      ethers.utils.formatEther(await creator.signer.getBalance())
    ) - parseFloat(creator.state)).to.equal(2)

    expect(parseFloat(
      ethers.utils.formatEther(await manager.signer.getBalance())
    ) - parseFloat(manager.state)).to.equal(1)

    expect(parseFloat(
      ethers.utils.formatEther(await tokenOwner.signer.getBalance())
    ) - parseFloat(tokenOwner.state)).to.equal(7)

    expect(
      Math.ceil(
        parseFloat(
          ethers.utils.formatEther(await buyer.signer.getBalance())
        ) - parseFloat(buyer.state)
      )
    ).to.equal(-10)
  })
})
