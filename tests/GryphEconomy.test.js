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

async function getSigners(token, treasury, economy) {
  //get the signers
  const signers = await ethers.getSigners()
  //attach contracts
  for (let i = 0; i < signers.length; i++) {
    const Token = await ethers.getContractFactory('GryphToken', signers[i])
    const Treasury = await ethers.getContractFactory('GryphTreasury', signers[i])
    const Economy = await ethers.getContractFactory('GryphEconomy', signers[i])
    signers[i].withToken = await Token.attach(token.address)
    signers[i].withTreasury = await Treasury.attach(treasury.address)
    signers[i].withEconomy = await Economy.attach(economy.address)
  }

  return signers
}

describe('GryphEconomy Tests', function () {
  before(async function() {
    this.contracts = {}
    this.contracts.token = await deploy('GryphToken')
    this.contracts.treasury = await deploy('GryphTreasury')
    this.contracts.economy = await deploy(
      'GryphEconomy', 
      this.contracts.token.address,
      this.contracts.treasury.address
    )
    
    const [
      owner,
      user1,
      user2,
      user3,
      user4,
      fund
    ] = await getSigners(
      this.contracts.token,
      this.contracts.treasury,
      this.contracts.economy
    )

    //send some ether and tokens
    await owner.withEconomy.unpause()
    await fund.sendTransaction({
      to: owner.withEconomy.address,
      value: ethers.utils.parseEther('10')
    })

    await owner.withToken.unpause()
    await owner.withToken.mint(
      owner.withEconomy.address,
      ethers.utils.parseEther('100')
    )

    this.signers = {
      owner,
      user1,
      user2,
      user3,
      user4
    }
  })
  
  it('Should have a balance', async function () {
    const { owner } = this.signers

    expect(await owner.withEconomy.provider.getBalance(owner.withEconomy.address)).to.equal(
      ethers.utils.parseEther('10')
    )

    expect(await owner.withToken.balanceOf(owner.withEconomy.address)).to.equal(
      ethers.utils.parseEther('100')
    )

    expect(await owner.withEconomy.balanceEther()).to.equal(
      ethers.utils.parseEther('10')
    )

    expect(await owner.withEconomy.balanceToken()).to.equal(
      ethers.utils.parseEther('100')
    )
  })
  
  it('Should have a buy and sell price', async function () {
    const { owner } = this.signers

    console.log('- ', (await owner.withEconomy.balanceEther()).toString())
    expect(await owner.withEconomy.buyingFor(
      ethers.utils.parseEther('10')
    )).to.equal(
      ethers.utils.parseEther('0.0000005')
    )

    expect(await owner.withEconomy.sellingFor(
      ethers.utils.parseEther('10')
    )).to.equal(
      ethers.utils.parseEther('0.000002')
    )
  })
  
  it('Should buy', async function () {
    const { owner, user1 } = this.signers

    await owner.withEconomy.buy(
      user1.address,
      ethers.utils.parseEther('10'),
      { value: ethers.utils.parseEther('0.000002') }
    )

    expect(await owner.withToken.balanceOf(user1.address)).to.equal(
      ethers.utils.parseEther('10')
    )

    expect(await owner.withEconomy.balanceEther()).to.equal(
      ethers.utils.parseEther('10.000001')
    )

    expect(await owner.provider.getBalance(owner.withEconomy.address)).to.equal(
      ethers.utils.parseEther('10.000001')
    )

    expect(await owner.provider.getBalance(owner.withTreasury.address)).to.equal(
      ethers.utils.parseEther('0.000001')
    )

    expect(await owner.withEconomy.balanceToken()).to.equal(
      ethers.utils.parseEther('90')
    )
  })
  
  it('Should sell', async function () {
    const { owner, user1 } = this.signers

    await user1.withToken.approve(
      owner.withEconomy.address,
      ethers.utils.parseEther('1')
    )

    await owner.withEconomy.sell(
      user1.address,
      ethers.utils.parseEther('1')
    )

    expect(await owner.withToken.balanceOf(user1.address)).to.equal(
      ethers.utils.parseEther('9')
    )

    expect(await owner.withEconomy.balanceEther()).to.equal(
      ethers.utils.parseEther('10.000000949999995')
    )

    expect(await owner.provider.getBalance(owner.withEconomy.address)).to.equal(
      ethers.utils.parseEther('10.000000949999995')
    )

    expect(await owner.provider.getBalance(owner.withTreasury.address)).to.equal(
      ethers.utils.parseEther('0.000001')
    )

    expect(await owner.withEconomy.balanceToken()).to.equal(
      ethers.utils.parseEther('91')
    )
  })
})