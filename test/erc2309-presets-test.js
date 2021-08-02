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

function hashToken(collectionId, key, account) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(
      ['uint256', 'uint256', 'address'],
      [collectionId, key, account]
    ).slice(2),
    'hex'
  )
}

describe('ERC2309 Preset Tests', function () {
  it('ERC2309PresetVanilla: Should deploy contract and mint', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC2309PresetVanilla',
      'GRYPH Street Art',
      'GRYPH'
    )

    //mint a token and transfer it to the recipient
    await owner.contract.mint(recipient.signer.address)

    expect(await owner.contract.ownerOf(1)).to.equal(recipient.signer.address)
  })

  it('ERC2309PresetBurnable: Should mint and burn token', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC2309PresetBurnable',
      'GRYPH Street Art',
      'GRYPH'
    )

    //mint a token and transfer it to the recipient
    await owner.contract.mint(recipient.signer.address)
    expect(await owner.contract.ownerOf(1)).to.equal(recipient.signer.address)

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

  it('ERC2309PresetCollection: Should create collections and mint tokens', async function () {
    const [owner, recipient1, recipient2, recipient3] = await getAccounts(
      4,
      'ERC2309PresetCollection',
      'GRYPH Street Art',
      'GRYPH',
      4
    )

    //create a collection
    await owner.contract.createCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      3
    )
    const collectionId = await owner.contract.LastCollectionId();
    expect(collectionId).to.equal(1)

    //mint a token in a collection and transfer it to the recipient
    await owner.contract.mintCollection(
      collectionId,
      recipient1.signer.address
    )
    const tokenId = await owner.contract.LastCollectionToken(collectionId)
    expect(tokenId).to.equal(10001)
    expect(await owner.contract.ownerOf(tokenId)).to.equal(recipient1.signer.address)

    //mint a token in a collection and transfer it to the recipient
    await owner.contract.mintCollectionBatch(collectionId, [
      recipient2.signer.address,
      recipient3.signer.address
    ])
    const lastTokenId = await owner.contract.LastCollectionToken(collectionId)
    expect(lastTokenId).to.equal(10003)
    expect(await owner.contract.ownerOf(10002)).to.equal(recipient2.signer.address)
    expect(await owner.contract.ownerOf(10003)).to.equal(recipient3.signer.address)

    //try to set the allowance greater than the precision
    let error = false
    try {
      await owner.contract.createCollection(
        'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
        10000
      )
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //try to over allocate
    error = false
    try {
      await owner.contract.mintCollectionBatch(collectionId, [
        recipient2.signer.address,
        recipient3.signer.address
      ])
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
    expect(lastTokenId).to.equal(10003)
  })

  it('ERC2309PresetCollectionDrops: Should allow redeeming of air drops', async function () {
    //we need to get the signers to add their address on contruction...
    const signers = await ethers.getSigners()

    //make the tree
    const merkleTree = new MerkleTree(
      [
        hashToken(1, 1, signers[1].address),
        hashToken(1, 2, signers[2].address)
      ],
      keccak256,
      { sortPairs: true }
    );

    //now build the accounts
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC2309PresetCollectionDrops',
      'GRYPH Street Art',
      'GRYPH',
      4
    )

    await owner.contract.dropCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      2,
      merkleTree.getHexRoot()
    )

    await owner.contract.redeem(
      1,
      1,
      recipient1.signer.address,
      merkleTree.getHexProof(
        hashToken(1, 1, recipient1.signer.address)
      )
    )

    expect(await owner.contract.ownerOf(10001)).to.equal(recipient1.signer.address)

    await owner.contract.redeem(
      1,
      2,
      recipient2.signer.address,
      merkleTree.getHexProof(
        hashToken(1, 2, recipient2.signer.address)
      )
    )

    expect(await owner.contract.ownerOf(10002)).to.equal(recipient2.signer.address)
  })

  it('ERC2309PresetOrderBook: Should list and delist token', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC2309PresetOrderBook',
      'GRYPH Street Art',
      'GRYPH'
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

  it('ERC2309PresetCollectionFees: Should add royalties', async function () {
    const [owner, recipient1, recipient2, recipient3] = await getAccounts(
      4,
      'ERC2309PresetCollectionFees',
      'GRYPH Street Art',
      'GRYPH',
      4
    )

    //create a collection
    await owner.contract.createCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      3
    )
    const collectionId = await owner.contract.LastCollectionId();
    expect(collectionId).to.equal(1)

    //set fee 1 (200 is 2.00%)
    await owner.contract.setFee(collectionId, recipient1.signer.address, 200)
    expect(await owner.contract.CollectionFee(
      collectionId,
      recipient1.signer.address
    )).to.equal(200)

    //set fee 2 (100 is 1.00%)
    await owner.contract.setFee(collectionId, recipient2.signer.address, 100)
    expect(await owner.contract.CollectionFee(
      collectionId,
      recipient2.signer.address
    )).to.equal(100)
    //total should now be 3.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(300)

    //try to over allocate
    let error = false
    try {
      await owner.contract.setFee(collectionId, recipient3.signer.address, 10000)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //set fee 3 (300 is 3.00%)
    await owner.contract.setFee(collectionId, recipient3.signer.address, 300)
    expect(await owner.contract.CollectionFee(
      collectionId,
      recipient3.signer.address
    )).to.equal(300)
    //total should now be 6.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(600)

    //reset fee 1 (2000 is 20.00%)
    await owner.contract.setFee(collectionId, recipient1.signer.address, 2000)
    expect(await owner.contract.CollectionFee(
      collectionId, recipient1.signer.address
    )).to.equal(2000)
    //total should now be 24.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(2400)

    //remove fee 2
    await owner.contract.removeFee(collectionId, recipient2.signer.address)
    //total should now be 23.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(2300)

    //remove fee of someone that hasn't been entered
    error = false
    try {
      await owner.contract.removeFee(collectionId, owner.signer.address)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
  })

  it('ERC2309PresetCollectionExchange: Should list and exchange token with royalties', async function () {
    const [contractOwner, creator, manager, tokenOwner, buyer] = await getAccounts(
      5,
      'ERC2309PresetCollectionExchange',
      'GRYPH Street Art',
      'GRYPH',
      4
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
    // This is the collection setup
    await contractOwner.contract.createCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      3
    )
    const collectionId = await contractOwner.contract.LastCollectionId()
    expect(collectionId).to.equal(1)

    //----------------------------------------//
    // This is the fee setup
    //The creator wants 20% (2000 is 20.00%)
    await contractOwner.contract.setFee(
      collectionId,
      creator.signer.address,
      2000
    )
    expect(
      await contractOwner.contract.CollectionFee(
        collectionId,
        creator.signer.address
      )
    ).to.equal(2000)

    //The manager wants 10% (1000 is 10.00%)
    await contractOwner.contract.setFee(
      collectionId,
      manager.signer.address,
      1000
    )
    expect(
      await contractOwner.contract.CollectionFee(
        collectionId,
        manager.signer.address
      )
    ).to.equal(1000)

    //total fees should now be 30.00%
    expect(await contractOwner.contract.CollectionFees(
      collectionId
    )).to.equal(3000)

    //----------------------------------------//
    // This is the minting
    //fast forward ... (go straight to the token owner)
    await contractOwner.contract.mintCollection(
      collectionId,
      tokenOwner.signer.address
    )
    const tokenId = await contractOwner.contract.LastCollectionToken(
      collectionId
    )
    expect(tokenId).to.equal(10001)
    expect(await contractOwner.contract.ownerOf(tokenId)).to.equal(
      tokenOwner.signer.address
    )

    //----------------------------------------//
    // This is the listing
    const listedAmount = ethers.utils.parseEther('10.0')
    //the token owner can only list their token for sale
    await tokenOwner.contract.list(tokenId, listedAmount)
    const listing1 = await tokenOwner.contract.getListing(tokenId)
    expect(listing1).to.equal(listedAmount)
    //update token owner state
    tokenOwner.state = parseFloat(
      ethers.utils.formatEther(await tokenOwner.signer.getBalance())
    )

    //----------------------------------------//
    // This is the exchange
    //let the buyer try to buy it for the wrong amount
    let error = false
    try {
      await buyer.contract.exchange(tokenId, {
        value: ethers.utils.parseEther('1.0')
      })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //the buyer will purchase it for the right amount
    await buyer.contract.exchange(tokenId, { value: listedAmount })

    //let the recipient try to buy it for the right amount again
    error = false
    try {
      await buyer.contract.exchange(tokenId, { value: listedAmount })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

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

  it('ERC2309PresetMarketplace: Should create collections and mint tokens', async function () {
    const [owner, recipient1, recipient2, recipient3] = await getAccounts(
      4,
      'ERC2309PresetMarketplace',
      'GRYPH Street Art',
      'GRYPH',
      4
    )

    //create a collection
    await owner.contract.createCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      3
    )
    const collectionId = await owner.contract.LastCollectionId();
    expect(collectionId).to.equal(1)

    //mint a token in a collection and transfer it to the recipient
    await owner.contract.mintCollection(
      collectionId,
      recipient1.signer.address
    )
    const tokenId = await owner.contract.LastCollectionToken(collectionId)
    expect(tokenId).to.equal(10001)
    expect(await owner.contract.ownerOf(tokenId)).to.equal(recipient1.signer.address)

    //mint a token in a collection and transfer it to the recipient
    await owner.contract.mintCollectionBatch(collectionId, [
      recipient2.signer.address,
      recipient3.signer.address
    ])
    const lastTokenId = await owner.contract.LastCollectionToken(collectionId)
    expect(lastTokenId).to.equal(10003)
    expect(await owner.contract.ownerOf(10002)).to.equal(recipient2.signer.address)
    expect(await owner.contract.ownerOf(10003)).to.equal(recipient3.signer.address)

    //try to set the allowance greater than the precision
    let error = false
    try {
      await owner.contract.createCollection(
        'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
        10000
      )
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //try to over allocate
    error = false
    try {
      await owner.contract.mintCollectionBatch(collectionId, [
        recipient2.signer.address,
        recipient3.signer.address
      ])
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
    expect(lastTokenId).to.equal(10003)
  })

  it('ERC2309PresetMarketplace: Should allow redeeming of air drops', async function () {
    //we need to get the signers to add their address on contruction...
    const signers = await ethers.getSigners()

    //make the tree
    const merkleTree = new MerkleTree(
      [
        hashToken(1, 1, signers[1].address),
        hashToken(1, 2, signers[2].address)
      ],
      keccak256,
      { sortPairs: true }
    );

    //now build the accounts
    const [owner, recipient1, recipient2] = await getAccounts(
      3,
      'ERC2309PresetMarketplace',
      'GRYPH Street Art',
      'GRYPH',
      4
    )

    await owner.contract.dropCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      2,
      merkleTree.getHexRoot()
    )

    await owner.contract.redeem(
      1,
      1,
      recipient1.signer.address,
      merkleTree.getHexProof(
        hashToken(1, 1, recipient1.signer.address)
      )
    )

    expect(await owner.contract.ownerOf(10001)).to.equal(recipient1.signer.address)

    await owner.contract.redeem(
      1,
      2,
      recipient2.signer.address,
      merkleTree.getHexProof(
        hashToken(1, 2, recipient2.signer.address)
      )
    )

    expect(await owner.contract.ownerOf(10002)).to.equal(recipient2.signer.address)
  })

  it('ERC2309PresetMarketplace: Should list and delist token', async function () {
    const [owner, recipient] = await getAccounts(
      2,
      'ERC2309PresetMarketplace',
      'GRYPH Street Art',
      'GRYPH',
      4
    )

    //create a collection
    await owner.contract.createCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      3
    )
    const collectionId = await owner.contract.LastCollectionId();
    expect(collectionId).to.equal(1)

    //mint a token in a collection and transfer it to the recipient
    await owner.contract.mintCollection(
      collectionId,
      recipient.signer.address
    )
    const tokenId = await owner.contract.LastCollectionToken(collectionId)
    expect(tokenId).to.equal(10001)
    expect(await owner.contract.ownerOf(tokenId)).to.equal(recipient.signer.address)

    //let the owner try to list the token for sale
    let error = false
    try {
      await owner.contract.list(10001, 500000)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to list the token for sale
    // where amount is in wei
    await recipient.contract.list(10001, 500000)
    const listing1 = await recipient.contract.getListing(10001)
    expect(listing1).to.equal(500000)

    //let the owner try to delist the token sale
    error = false
    try {
      await owner.contract.delist(10001)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //let the recipient try to delist
    await recipient.contract.delist(10001)
    const listing2 = await recipient.contract.getListing(10001)
    expect(listing2).to.equal(0)

    //even non existent tokens are 0
    const listing3 = await recipient.contract.getListing(100)
    expect(listing3).to.equal(0)
  })

  it('ERC2309PresetMarketplace: Should add royalties', async function () {
    const [owner, recipient1, recipient2, recipient3] = await getAccounts(
      4,
      'ERC2309PresetMarketplace',
      'GRYPH Street Art',
      'GRYPH',
      4
    )

    //create a collection
    await owner.contract.createCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      3
    )
    const collectionId = await owner.contract.LastCollectionId();
    expect(collectionId).to.equal(1)

    //set fee 1 (200 is 2.00%)
    await owner.contract.setFee(collectionId, recipient1.signer.address, 200)
    expect(await owner.contract.CollectionFee(
      collectionId,
      recipient1.signer.address
    )).to.equal(200)

    //set fee 2 (100 is 1.00%)
    await owner.contract.setFee(collectionId, recipient2.signer.address, 100)
    expect(await owner.contract.CollectionFee(
      collectionId,
      recipient2.signer.address
    )).to.equal(100)
    //total should now be 3.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(300)

    //try to over allocate
    let error = false
    try {
      await owner.contract.setFee(collectionId, recipient3.signer.address, 10000)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //set fee 3 (300 is 3.00%)
    await owner.contract.setFee(collectionId, recipient3.signer.address, 300)
    expect(await owner.contract.CollectionFee(
      collectionId,
      recipient3.signer.address
    )).to.equal(300)
    //total should now be 6.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(600)

    //reset fee 1 (2000 is 20.00%)
    await owner.contract.setFee(collectionId, recipient1.signer.address, 2000)
    expect(await owner.contract.CollectionFee(
      collectionId, recipient1.signer.address
    )).to.equal(2000)
    //total should now be 24.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(2400)

    //remove fee 2
    await owner.contract.removeFee(collectionId, recipient2.signer.address)
    //total should now be 23.00%
    expect(await owner.contract.CollectionFees(collectionId)).to.equal(2300)

    //remove fee of someone that hasn't been entered
    error = false
    try {
      await owner.contract.removeFee(collectionId, owner.signer.address)
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)
  })

  it('ERC2309PresetMarketplace: Should list and exchange token with royalties', async function () {
    const [contractOwner, creator, manager, tokenOwner, buyer] = await getAccounts(
      5,
      'ERC2309PresetMarketplace',
      'GRYPH Street Art',
      'GRYPH',
      4
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
    // This is the collection setup
    await contractOwner.contract.createCollection(
      'ipfs://QmfAHGBLjFtXESBqGSU4TjPGL88LbVAbZoVYz59Hvnv9tF',
      3
    )
    const collectionId = await contractOwner.contract.LastCollectionId()
    expect(collectionId).to.equal(1)

    //----------------------------------------//
    // This is the fee setup
    //The creator wants 20% (2000 is 20.00%)
    await contractOwner.contract.setFee(
      collectionId,
      creator.signer.address,
      2000
    )
    expect(
      await contractOwner.contract.CollectionFee(
        collectionId,
        creator.signer.address
      )
    ).to.equal(2000)

    //The manager wants 10% (1000 is 10.00%)
    await contractOwner.contract.setFee(
      collectionId,
      manager.signer.address,
      1000
    )
    expect(
      await contractOwner.contract.CollectionFee(
        collectionId,
        manager.signer.address
      )
    ).to.equal(1000)

    //total fees should now be 30.00%
    expect(await contractOwner.contract.CollectionFees(
      collectionId
    )).to.equal(3000)

    //----------------------------------------//
    // This is the minting
    //fast forward ... (go straight to the token owner)
    await contractOwner.contract.mintCollection(
      collectionId,
      tokenOwner.signer.address
    )
    const tokenId = await contractOwner.contract.LastCollectionToken(
      collectionId
    )
    expect(tokenId).to.equal(10001)
    expect(await contractOwner.contract.ownerOf(tokenId)).to.equal(
      tokenOwner.signer.address
    )

    //----------------------------------------//
    // This is the listing
    const listedAmount = ethers.utils.parseEther('10.0')
    //the token owner can only list their token for sale
    await tokenOwner.contract.list(tokenId, listedAmount)
    const listing1 = await tokenOwner.contract.getListing(tokenId)
    expect(listing1).to.equal(listedAmount)
    //update token owner state
    tokenOwner.state = parseFloat(
      ethers.utils.formatEther(await tokenOwner.signer.getBalance())
    )

    //----------------------------------------//
    // This is the exchange
    //let the buyer try to buy it for the wrong amount
    let error = false
    try {
      await buyer.contract.exchange(tokenId, {
        value: ethers.utils.parseEther('1.0')
      })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

    //the buyer will purchase it for the right amount
    await buyer.contract.exchange(tokenId, { value: listedAmount })

    //let the recipient try to buy it for the right amount again
    error = false
    try {
      await buyer.contract.exchange(tokenId, { value: listedAmount })
    } catch (e) {
      error = true
    }
    expect(error).to.equal(true)

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
