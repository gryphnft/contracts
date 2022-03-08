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

describe('GryphNamespaces Tests', function () {
  before(async function() {
    const [ 
      owner, 
      holder1, 
      holder2
    ] = await getSigners('GryphNamespaces', 'https://ipfs.io/ipfs/bafkreicw32mefimobvabviirb7rao45r3kpy5zdudiputyubcmp2gag4xa')

    await owner.withContract.setBaseURI('http://localhost:3000')
    
    this.signers = {
      owner, 
      holder1, 
      holder2
    }
  })
  
  it('Should mint', async function () {
    const { owner, holder1 } = this.signers
    await owner.withContract.mint(holder1.address, 'test')
    expect(await owner.withContract.tokenURI(1)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(1)).to.equal('test')
    expect(await owner.withContract.reserved('test')).to.equal(1)

    await owner.withContract.mint(holder1.address, 'a')
    expect(await owner.withContract.tokenURI(2)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(2)).to.equal('a')
    expect(await owner.withContract.reserved('a')).to.equal(2)
  })

  it('Should not mint', async function () {
    const { owner, holder1 } = this.signers

    await expect(
      owner.withContract.mint(holder1.address, 'test')
    ).to.revertedWith('InvalidName()')
  })

  it('Should buy', async function () {
    const { owner, holder1 } = this.signers
    owner.withContract.buy(
      holder1.address, 
      'abcd', 
      { value: ethers.utils.parseEther('0.192') }
    )
    expect(await owner.withContract.tokenURI(3)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(3)).to.equal('abcd')
    expect(await owner.withContract.reserved('abcd')).to.equal(3)

    owner.withContract.buy(
      holder1.address, 
      'abcde', 
      { value: ethers.utils.parseEther('0.096') }
    )
    expect(await owner.withContract.tokenURI(4)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(4)).to.equal('abcde')
    expect(await owner.withContract.reserved('abcde')).to.equal(4)

    owner.withContract.buy(
      holder1.address, 
      'abcdef', 
      { value: ethers.utils.parseEther('0.048') }
    )
    expect(await owner.withContract.tokenURI(5)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(5)).to.equal('abcdef')
    expect(await owner.withContract.reserved('abcdef')).to.equal(5)

    owner.withContract.buy(
      holder1.address, 
      'abcdefg', 
      { value: ethers.utils.parseEther('0.024') }
    )
    expect(await owner.withContract.tokenURI(6)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(6)).to.equal('abcdefg')
    expect(await owner.withContract.reserved('abcdefg')).to.equal(6)

    owner.withContract.buy(
      holder1.address, 
      'abcdefgh', 
      { value: ethers.utils.parseEther('0.012') }
    )
    expect(await owner.withContract.tokenURI(7)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(7)).to.equal('abcdefgh')
    expect(await owner.withContract.reserved('abcdefgh')).to.equal(7)

    owner.withContract.buy(
      holder1.address, 
      'abcdefghi', 
      { value: ethers.utils.parseEther('0.006') }
    )
    expect(await owner.withContract.tokenURI(8)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(8)).to.equal('abcdefghi')
    expect(await owner.withContract.reserved('abcdefghi')).to.equal(8)

    owner.withContract.buy(
      holder1.address, 
      'abcdefghij', 
      { value: ethers.utils.parseEther('0.003') }
    )
    expect(await owner.withContract.tokenURI(9)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(9)).to.equal('abcdefghij')
    expect(await owner.withContract.reserved('abcdefghij')).to.equal(9)
  })

  it('Should not buy', async function () {
    const { owner, holder1 } = this.signers

    await expect(
      owner.withContract.buy(
        holder1.address, 
        'test', 
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('InvalidName()')

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
    ).to.revertedWith('InvalidName()')
  })

  it('Should blacklist', async function () {
    const { owner, holder1 } = this.signers
    await owner.withContract.blacklist(['mint'])
    await expect(
      owner.withContract.buy(
        holder1.address, 
        'mint', 
        { value: ethers.utils.parseEther('0.192') }
      )
    ).to.revertedWith('InvalidName()')
  })

  it('Should not blacklist', async function () {
    const { owner, holder1 } = this.signers
    await expect(
      owner.withContract.blacklist(['abcd'])
    ).to.revertedWith('InvalidName()')
  })
  
  it('Should whitelist', async function () {
    const { owner, holder1 } = this.signers
    await owner.withContract.whitelist(['mint'])

    owner.withContract.buy(
      holder1.address, 
      'mint', 
      { value: ethers.utils.parseEther('0.192') }
    )
    expect(await owner.withContract.tokenURI(10)).to.contain('data:application/json;base64,')
    expect(await owner.withContract.tokenName(10)).to.equal('mint')
    expect(await owner.withContract.reserved('mint')).to.equal(10)
  })
})