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

async function getSigners(token, treasury, economy, vesting) {
  //get the signers
  const signers = await ethers.getSigners()
  //attach contracts
  for (let i = 0; i < signers.length; i++) {
    const Token = await ethers.getContractFactory('GryphToken', signers[i])
    const Treasury = await ethers.getContractFactory('GryphTreasury', signers[i])
    const Economy = await ethers.getContractFactory('GryphEconomy', signers[i])
    const Vesting = await ethers.getContractFactory('GryphVesting', signers[i])
    signers[i].withToken = await Token.attach(token.address)
    signers[i].withTreasury = await Treasury.attach(treasury.address)
    signers[i].withEconomy = await Economy.attach(economy.address)
    signers[i].withVesting = await Vesting.attach(vesting.address)
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

describe('GryphVesting Tests', function () {
  before(async function() {
    this.contracts = {}
    this.contracts.token = await deploy('GryphToken')
    this.contracts.treasury = await deploy('GryphTreasury')
    this.contracts.economy = await deploy(
      'GryphEconomy', 
      this.contracts.token.address
    )
    this.contracts.vesting = await deploy(
      'GryphVesting', 
      this.contracts.token.address, 
      this.contracts.treasury.address, 
      this.contracts.economy.address
    )
    const [
      owner,
      investor1, 
      investor2, 
      investor3, 
      investor4
    ] = await getSigners(
      this.contracts.token,
      this.contracts.treasury,
      this.contracts.economy,
      this.contracts.vesting
    )

    await owner.withToken.grantRole(
      getRole('MINTER_ROLE'), 
      this.contracts.vesting.address
    )

    this.contracts.vesting = owner.withVesting.address

    this.signers = {
      owner,
      investor1, 
      investor2, 
      investor3, 
      investor4
    }
  })
  
  it('Should error when buying', async function () {
    const { owner, investor1 } = this.signers
    await expect(
      owner.withVesting.buy(
        investor1.address, 
        ethers.utils.parseEther('100000'),
        { value: ethers.utils.parseEther('1') }
      )
    ).to.be.revertedWith('InvalidVesting()')
  })

  it('Should set the vesting stage', async function () {
    const { owner } = this.signers
    await owner.withVesting.stage(
      ethers.utils.parseEther('0.00001'), 
      ethers.utils.parseEther('1000000')
    )
    expect(await owner.withVesting.currentTokenPrice()).to.equal(
      ethers.utils.parseEther('0.00001')
    )
    expect(await owner.withVesting.currentTokenLimit()).to.equal(
      ethers.utils.parseEther('1000000')
    )

    await expect(
      owner.withVesting.stage(
        ethers.utils.parseEther('0.000005'), 
        ethers.utils.parseEther('1000001')
      )
    ).to.be.revertedWith('InvalidStage()')

    await expect(
      owner.withVesting.stage(
        ethers.utils.parseEther('0.00002'), 
        ethers.utils.parseEther('900000')
      )
    ).to.be.revertedWith('InvalidStage()')
  })

  it('Should buy', async function () {
    const { owner, investor1, investor2, investor3 } = this.signers
    await owner.withVesting.buy(
      investor1.address, 
      ethers.utils.parseEther('100000'),
      { value: ethers.utils.parseEther('1') }
    )
    expect(await owner.withVesting.vestingTokens(investor1.address)).to.equal(
      ethers.utils.parseEther('100000')
    )
    expect(await owner.withVesting.etherCollected(investor1.address)).to.equal(
      ethers.utils.parseEther('1')
    )

    await owner.withVesting.buy(
      investor2.address, 
      ethers.utils.parseEther('100000'),
      { value: ethers.utils.parseEther('1') }
    )
    expect(await owner.withVesting.vestingTokens(investor2.address)).to.equal(
      ethers.utils.parseEther('100000')
    )
    expect(await owner.withVesting.etherCollected(investor2.address)).to.equal(
      ethers.utils.parseEther('1')
    )

    await owner.withVesting.buy(
      investor3.address, 
      ethers.utils.parseEther('100000'),
      { value: ethers.utils.parseEther('1') }
    )
    expect(await owner.withVesting.vestingTokens(investor3.address)).to.equal(
      ethers.utils.parseEther('100000')
    )
    expect(await owner.withVesting.etherCollected(investor3.address)).to.equal(
      ethers.utils.parseEther('1')
    )
  })

  it('Should vest', async function () {
    const { owner, investor3, investor4 } = this.signers

    await owner.withVesting.vest(
      investor3.address, 
      ethers.utils.parseEther('100000')
    )
    expect(await owner.withVesting.vestingTokens(investor3.address)).to.equal(
      ethers.utils.parseEther('200000')
    )
    expect(await owner.withVesting.etherCollected(investor3.address)).to.equal(
      ethers.utils.parseEther('1')
    )

    await owner.withVesting.vest(
      investor4.address, 
      ethers.utils.parseEther('100000')
    )
    expect(await owner.withVesting.vestingTokens(investor4.address)).to.equal(
      ethers.utils.parseEther('100000')
    )
    expect(await owner.withVesting.etherCollected(investor4.address)).to.equal(0)
  })

  it('Should not refund', async function () {
    const { owner, investor1, investor2, investor3, investor4 } = this.signers
    
    await expect(
      owner.withVesting.refund(investor1.address)
    ).to.be.revertedWith('InvalidRefund()')

    await expect(
      owner.withVesting.refund(investor2.address)
    ).to.be.revertedWith('InvalidRefund()')

    await expect(
      owner.withVesting.refund(investor3.address)
    ).to.be.revertedWith('InvalidRefund()')

    await expect(
      owner.withVesting.refund(investor4.address)
    ).to.be.revertedWith('InvalidRefund()')
  })

  it('Should refund all', async function () {
    const { owner, investor1, investor2, investor3, investor4 } = this.signers
    await owner.withVesting.refundAll(true)
    await owner.withVesting.refund(investor1.address)
    expect(await owner.withVesting.vestingTokens(investor1.address)).to.equal(0)
    expect(await owner.withVesting.etherCollected(investor1.address)).to.equal(0)

    await expect(
      owner.withVesting.refund(investor4.address)
    ).to.be.revertedWith('InvalidRefund()')

    await expect(
      owner.withVesting.buy(
        investor1.address, 
        ethers.utils.parseEther('100000'),
        { value: ethers.utils.parseEther('1') }
      )
    ).to.be.revertedWith('InvalidVesting()')

    await expect(
      owner.withVesting.vest(
        investor1.address, 
        ethers.utils.parseEther('100000')
      )
    ).to.be.revertedWith('InvalidVesting()')
    await owner.withVesting.refundAll(false)
  })

  it('Should unlock', async function () {
    const { owner, investor1, investor2, investor3, investor4 } = this.signers
    const now = Math.floor((Date.now()) / 1000)
    const vested = 1714521600;
    await owner.withVesting.unlock(now - 1000)

    const earned1 = ethers.utils.parseEther('100000').mul(1000).div(vested - (now - 1000))
    const earned2 = ethers.utils.parseEther('200000').mul(1000).div(vested - (now - 1000))
    expect(await owner.withVesting.totalReleasableAmount(investor1.address, now)).to.equal(0)
    expect(await owner.withVesting.totalReleasableAmount(investor2.address, now)).to.equal(earned1)
    expect(await owner.withVesting.totalReleasableAmount(investor3.address, now)).to.equal(earned2)
    expect(await owner.withVesting.totalReleasableAmount(investor4.address, now)).to.equal(earned1)

    expect(await owner.withVesting.totalReleasableAmount(investor1.address, vested)).to.equal(0)
    expect(await owner.withVesting.totalReleasableAmount(investor2.address, vested)).to.equal(
      ethers.utils.parseEther('100000')
    )
    expect(await owner.withVesting.totalReleasableAmount(investor3.address, vested)).to.equal(
      ethers.utils.parseEther('200000')
    )
    expect(await owner.withVesting.totalReleasableAmount(investor4.address, vested)).to.equal(
      ethers.utils.parseEther('100000')
    )
  })

  it('Should withdraw', async function () {
    const { owner } = this.signers
    await owner.withVesting.sendToTreasury(ethers.utils.parseEther('1'))
    await owner.withVesting.sendToEconomy(ethers.utils.parseEther('1'))

    expect(await owner.withTreasury.provider.getBalance(owner.withTreasury.address)).to.equal(
      ethers.utils.parseEther('1')
    )

    expect(await owner.withEconomy.provider.getBalance(owner.withEconomy.address)).to.equal(
      ethers.utils.parseEther('1')
    )
  })

  it('Should time travel to May 1, 2024', async function () {  
    await ethers.provider.send('evm_mine');
    await ethers.provider.send('evm_setNextBlockTimestamp', [1714521601]); 
    await ethers.provider.send('evm_mine');
  })

  it('Should release all', async function () {
    const { owner, investor1, investor2, investor3, investor4 } = this.signers
    await owner.withToken.unpause()
    await owner.withVesting.release(investor2.address)
    await owner.withVesting.release(investor3.address)
    await owner.withVesting.release(investor4.address)

    expect(await owner.withToken.balanceOf(investor1.address)).to.equal(0)

    expect(await owner.withToken.balanceOf(investor2.address)).to.equal(
      ethers.utils.parseEther('100000')
    )

    expect(await owner.withToken.balanceOf(investor3.address)).to.equal(
      ethers.utils.parseEther('200000')
    )

    expect(await owner.withToken.balanceOf(investor4.address)).to.equal(
      ethers.utils.parseEther('100000')
    )
    
  })
})