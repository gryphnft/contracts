const { expect } = require('chai');
require('dotenv').config()

if (process.env.BLOCKCHAIN_NETWORK != 'hardhat') {
  console.error('Exited testing with network:', process.env.BLOCKCHAIN_NETWORK)
  process.exit(1);
}

async function deploy(name, ...params) {
  //deploy the contract
  const ContractFactory = await ethers.getContractFactory(name)
  const contract = await upgrades.deployProxy(
    ContractFactory, 
    params, 
    { initializer: 'initialize'}
  )
  await contract.deployed()

  return contract
}

async function getSigners(name, ...params) {
  //deploy the contract
  const contract = await deploy(name, ...params)
  
  //get the signers
  const signers = await ethers.getSigners()
  //attach contracts
  for (let i = 0; i < signers.length; i++) {
    const Contract = await ethers.getContractFactory(name, signers[i])
    signers[i].withContract = await Contract.attach(contract.address)
  }

  return signers
}

function getTokenId(name) {
  const labelHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(name))
  return ethers.BigNumber.from(labelHash).toString()
}

describe('GryphNamespaces Tests', function () {
  before(async function() {
    const [ 
      owner, 
      holder1, 
      holder2
    ] = await getSigners('GryphNamespaces', 'https://ipfs.io/ipfs/bafkreicw32mefimobvabviirb7rao45r3kpy5zdudiputyubcmp2gag4xa')

    this.signers = {
      owner, 
      holder1, 
      holder2
    }
  })
  
  it('Should mint', async function () {
    const { owner, holder1 } = this.signers
    await owner.withContract.mint(holder1.address, 'test')
    let tokenId = getTokenId('test')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    await owner.withContract.mint(holder1.address, 'a')
    tokenId = getTokenId('a')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')
  })

  it('Should not mint', async function () {
    const { owner, holder1 } = this.signers

    await expect(
      owner.withContract.mint(holder1.address, 'test')
    ).to.revertedWith('ExistentToken()')
  })

  it('Should buy', async function () {
    const { owner, holder1 } = this.signers
    owner.withContract.buy(
      holder1.address, 
      'abcd', 
      { value: ethers.utils.parseEther('0.192') }
    )
    let tokenId = getTokenId('abcd')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withContract.buy(
      holder1.address, 
      'abcde', 
      { value: ethers.utils.parseEther('0.096') }
    )
    tokenId = getTokenId('abcde')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withContract.buy(
      holder1.address, 
      'abcdef', 
      { value: ethers.utils.parseEther('0.048') }
    )
    tokenId = getTokenId('abcdef')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withContract.buy(
      holder1.address, 
      'abcdefg', 
      { value: ethers.utils.parseEther('0.024') }
    )
    tokenId = getTokenId('abcdefg')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withContract.buy(
      holder1.address, 
      'abcdefgh', 
      { value: ethers.utils.parseEther('0.012') }
    )
    tokenId = getTokenId('abcdefgh')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withContract.buy(
      holder1.address, 
      'abcdefghi', 
      { value: ethers.utils.parseEther('0.006') }
    )
    tokenId = getTokenId('abcdefghi')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')

    owner.withContract.buy(
      holder1.address, 
      'abcdefghij', 
      { value: ethers.utils.parseEther('0.003') }
    )
    tokenId = getTokenId('abcdefghij')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')
  })

  it('Should not buy', async function () {
    const { owner, holder1 } = this.signers

    await expect(
      owner.withContract.buy(
        holder1.address, 
        'test', 
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('ExistentToken()')

    await expect(
      owner.withContract.buy(
        holder1.address, 
        'abc', 
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('InvalidName()')

    await expect(
      owner.withContract.buy(
        holder1.address, 
        'abcd', 
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('ExistentToken()')
  })

  it('Should blacklist', async function () {
    const { owner, holder1 } = this.signers
    await owner.withContract.blacklist(['mint'])
  })
  
  it('Should whitelist', async function () {
    const { owner, holder1 } = this.signers
    await owner.withContract.whitelist(['mint'])

    owner.withContract.buy(
      holder1.address, 
      'mint', 
      { value: ethers.utils.parseEther('0.192') }
    )
    let tokenId = getTokenId('abcd')
    expect(await owner.withContract.tokenURI(tokenId)).to.contain('data:application/json;base64,')
  })
})