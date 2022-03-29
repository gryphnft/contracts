const { expect } = require('chai');
require('dotenv').config()

if (process.env.BLOCKCHAIN_NETWORK != 'hardhat') {
  console.error('Exited testing with network:', process.env.BLOCKCHAIN_NETWORK)
  process.exit(1);
}

async function deploy(name, ...params) {
  //deploy the contract
  const ContractFactory = await ethers.getContractFactory(name)
  const contract = await ContractFactory.deploy(...params)
  await contract.deployed()

  return contract
}

async function getSigners(key, name, ...params) {
  //deploy the contract
  const contract = await deploy(name, ...params)
  //get the signers
  const signers = await ethers.getSigners()
  return await bindContract(key, name, contract, signers)
}

async function bindContract(key, name, contract, signers) {
  //attach contracts
  for (let i = 0; i < signers.length; i++) {
    const Contract = await ethers.getContractFactory(name, signers[i])
    signers[i][key] = await Contract.attach(contract.address)
  }

  return signers
}

function getRole(name) {
  if (!name || name === 'DEFAULT_ADMIN_ROLE') {
    return '0x0000000000000000000000000000000000000000000000000000000000000000';
  }

  return '0x' + Buffer.from(
    ethers.utils.solidityKeccak256(['string'], [name]).slice(2), 
    'hex'
  ).toString('hex')

}

function getTokenId(name) {
  const labelHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(name))
  return ethers.BigNumber.from(labelHash).toString()
}

describe('GryphNamespaces Tests', function () {
  before(async function() {
    //deploy registry
    this.registry = await deploy(
      'GryphNamespaceRegistry', 
      'https://ipfs.io/ipfs/bafkreicw32mefimobvabviirb7rao45r3kpy5zdudiputyubcmp2gag4xa'
    )

    //deploy sale
    const signers = await getSigners(
      'withSale',
      'GryphNamespaceSale', 
      this.registry.address
    )

    //bind the registry
    const [ 
      owner, 
      referrer,
      holder1, 
      holder2
    ] = await bindContract(
      'withRegistry', 
      'GryphNamespaceRegistry', 
      this.registry, 
      signers
    )

    //allow sale to mint in regitry
    await owner.withRegistry.grantRole(getRole('MINTER_ROLE'), owner.withSale.address)
    //allow self to mint in regitry
    await owner.withRegistry.grantRole(getRole('MINTER_ROLE'), owner.address)
    //grant self to curate the registry
    await owner.withRegistry.grantRole(getRole('CURATOR_ROLE'), owner.address)
    
    this.zero = '0x0000000000000000000000000000000000000000'

    this.signers = {
      owner, 
      referrer,
      holder1, 
      holder2
    }
  })
  
  it('Should mint', async function () {
    const { owner, holder1 } = this.signers
    await owner.withRegistry.mint(holder1.address, 'test')
    let tokenId = getTokenId('test')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain(
      'data:application/json;base64,'
    )

    await owner.withRegistry.mint(holder1.address, 'a')
    tokenId = getTokenId('a')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain('data:application/json;base64,')
  })

  it('Should not mint', async function () {
    const { owner, holder1 } = this.signers

    await expect(
      owner.withRegistry.mint(holder1.address, 'test')
    ).to.revertedWith('InvalidCall()')
  })

  it('Should buy', async function () {
    const { owner, holder1 } = this.signers
    owner.withSale.buy(
      holder1.address, 'abcd', this.zero,
      { value: ethers.utils.parseEther('0.192') }
    )
    let tokenId = getTokenId('abcd')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain(
      'data:application/json;base64,'
    )

    owner.withSale.buy(
      holder1.address, 'abcde', this.zero,
      { value: ethers.utils.parseEther('0.096') }
    )
    tokenId = getTokenId('abcde')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain(
      'data:application/json;base64,'
    )

    owner.withSale.buy(
      holder1.address, 'abcdef', this.zero,
      { value: ethers.utils.parseEther('0.048') }
    )
    tokenId = getTokenId('abcdef')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withSale.buy(
      holder1.address, 'abcdefg', this.zero,
      { value: ethers.utils.parseEther('0.024') }
    )
    tokenId = getTokenId('abcdefg')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withSale.buy(
      holder1.address, 'abcdefgh', this.zero,
      { value: ethers.utils.parseEther('0.012') }
    )
    tokenId = getTokenId('abcdefgh')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withSale.buy(
      holder1.address, 'abcdefghi', this.zero,
      { value: ethers.utils.parseEther('0.006') }
    )
    tokenId = getTokenId('abcdefghi')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withSale.buy(
      holder1.address, 'abcdefghij', this.zero,
      { value: ethers.utils.parseEther('0.003') }
    )
    tokenId = getTokenId('abcdefghij')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain('data:application/json;base64,')
  })

  it('Should not buy', async function () {
    const { owner, holder1 } = this.signers

    await expect(//token exists
      owner.withSale.buy(
        holder1.address, 'test', '0x0000000000000000000000000000000000000000',
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('InvalidCall()')

    await expect(//invalid name
      owner.withSale.buy(
        holder1.address, 'abc', '0x0000000000000000000000000000000000000000',
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('InvalidCall()')

    await expect(//token exists
      owner.withSale.buy(
        holder1.address, 'abcd', '0x0000000000000000000000000000000000000000',
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('InvalidCall()')
  })

  it('Should blacklist', async function () {
    const { owner, holder1 } = this.signers
    await owner.withRegistry.blacklist(['mint'], true)
  })
  
  it('Should whitelist', async function () {
    const { owner, holder1 } = this.signers
    await owner.withRegistry.blacklist(['mint'], false)

    owner.withSale.buy(
      holder1.address, 'mint', '0x0000000000000000000000000000000000000000',
      { value: ethers.utils.parseEther('0.192') }
    )
    let tokenId = getTokenId('abcd')
    expect(await owner.withRegistry.tokenURI(tokenId)).to.contain('data:application/json;base64,')
  })

  it('Should refer and redeem', async function () {
    const { owner, holder1, referrer } = this.signers
    owner.withSale.buy(
      holder1.address, 'wxyz', referrer.address,
      { value: ethers.utils.parseEther('0.192') }
    )

    expect(
      await owner.withSale.rewards(referrer.address)
    ).to.equal(ethers.utils.parseEther('0.0096'))

    const startingBalance = await referrer.getBalance()
    await owner.withSale.redeem(referrer.address)

    expect(//expecting 0.0096
      (await referrer.getBalance()).sub(startingBalance)
    ).to.equal(ethers.utils.parseEther('0.0096'))
  })
})