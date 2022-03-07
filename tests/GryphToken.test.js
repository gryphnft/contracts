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

describe('GryphToken Tests', function () {
  before(async function() {
    const [ 
      owner, 
      holder1, 
      holder2, 
      holder3, 
      holder4
    ] = await getSigners('GryphToken')

    this.signers = {
      owner, 
      holder1, 
      holder2, 
      holder3, 
      holder4
    }
  })

  it('Should not mint when paused', async function () {
    const { owner, holder1 } = this.signers
    await expect(
      owner.withContract.mint(holder1.address, ethers.utils.parseEther('10'))
    ).to.revertedWith('Pausable: paused')
  })
  
  it('Should mint', async function () {
    const { owner, holder1 } = this.signers

    await owner.withContract.unpause()
    await owner.withContract.mint(holder1.address, ethers.utils.parseEther('10'))
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('10')
    )
  })
  
  it('Should transfer', async function () {
    const { owner, holder1, holder2 } = this.signers

    await holder1.withContract.transfer(holder2.address, ethers.utils.parseEther('5'))
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('5')
    )

    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(
      ethers.utils.parseEther('5')
    )
  })

  it('Should not transfer when paused', async function () {
    const { owner, holder1, holder2 } = this.signers
    await owner.withContract.pause()
    await expect(
      holder1.withContract.transfer(holder2.address, ethers.utils.parseEther('5'))
    ).to.revertedWith('Token transfer while paused')
  })
})