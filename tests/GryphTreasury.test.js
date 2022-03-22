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

function getRole(name) {
  if (!name || name === 'DEFAULT_ADMIN_ROLE') {
    return '0x0000000000000000000000000000000000000000000000000000000000000000';
  }

  return '0x' + Buffer.from(
    ethers.utils.solidityKeccak256(['string'], [name]).slice(2), 
    'hex'
  ).toString('hex')

}

describe('GryphTreasury Tests', function () {
  before(async function() {
    const [ 
      owner, 
      requester,
      receiver, 
      approver1, 
      approver2, 
      approver3, 
      approver4,
      fund1,
      fund2,
      fund3
    ] = await getSigners('GryphTreasury')

    await owner.withContract.grantRole(getRole('REQUESTER_ROLE'), requester.address)
    await owner.withContract.grantRole(getRole('REQUESTER_ROLE'), approver1.address)
    await owner.withContract.grantRole(getRole('APPROVER_ROLE'), approver1.address)
    await owner.withContract.grantRole(getRole('APPROVER_ROLE'), approver2.address)
    await owner.withContract.grantRole(getRole('APPROVER_ROLE'), approver3.address)
    await owner.withContract.grantRole(getRole('APPROVER_ROLE'), approver4.address)

    await fund1.sendTransaction({
      to: owner.withContract.address,
      value: ethers.utils.parseEther('10')
    })

    await fund2.sendTransaction({
      to: owner.withContract.address,
      value: ethers.utils.parseEther('10')
    })

    await fund3.sendTransaction({
      to: owner.withContract.address,
      value: ethers.utils.parseEther('1')
    })

    this.txURI = 'https://ipfs.io/ipfs/Qm123abc'

    this.signers = {
      owner, 
      requester, 
      receiver,
      approver1, 
      approver2, 
      approver3, 
      approver4
    }
  })
  
  it('Should return the correct tiers', async function() {
    const { requester, receiver } = this.signers
    expect(
      await requester.withContract.tier(ethers.utils.parseEther('0.01'))
    ).to.equal(1)
    expect(
      await requester.withContract.tier(ethers.utils.parseEther('0.05'))
    ).to.equal(1)

    expect(
      await requester.withContract.tier(ethers.utils.parseEther('0.1'))
    ).to.equal(2)
    expect(
      await requester.withContract.tier(ethers.utils.parseEther('0.5'))
    ).to.equal(2)

    expect(
      await requester.withContract.tier(ethers.utils.parseEther('1'))
    ).to.equal(3)
    expect(
      await requester.withContract.tier(ethers.utils.parseEther('5'))
    ).to.equal(3)

    expect(
      await requester.withContract.tier(ethers.utils.parseEther('10'))
    ).to.equal(4)
    expect(
      await requester.withContract.tier(ethers.utils.parseEther('20'))
    ).to.equal(4)

    expect(
      await requester.withContract.tier(ethers.utils.parseEther('21'))
    ).to.equal(0)
  })
  
  it('Should request tx', async function() {
    const { requester, receiver } = this.signers
    await expect(
      requester.withContract.request(1, 
        receiver.address, 
        ethers.utils.parseEther('0.05'), 
        this.txURI
      )
    ).to.emit(requester.withContract, 'FundsRequested').withArgs(1)
    let tx = await requester.withContract.txs(1)
    expect(tx.beneficiary).to.equal(receiver.address)
    expect(tx.amount).to.equal(ethers.utils.parseEther('0.05'))
    expect(tx.approvals).to.equal(0)
    expect(tx.withdrawn).to.equal(false)

    await expect(
      requester.withContract.request(2, 
        receiver.address, 
        ethers.utils.parseEther('5'), 
        this.txURI
      )
    ).to.emit(requester.withContract, 'FundsRequested').withArgs(2)
    tx = await requester.withContract.txs(2)
    expect(tx.beneficiary).to.equal(receiver.address)
    expect(tx.amount).to.equal(ethers.utils.parseEther('5'))
    expect(tx.approvals).to.equal(0)
    expect(tx.withdrawn).to.equal(false)
  })

  it('Should error when using the same tx id', async function() {
    const { requester, receiver } = this.signers
    await expect(
      requester.withContract.request(1, receiver.address, ethers.utils.parseEther('0.5'), this.txURI)
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should not allow more than 20 eth', async function() {
    const { requester, receiver } = this.signers
    await expect(
      requester.withContract.request(3, receiver.address, ethers.utils.parseEther('20.01'), this.txURI)
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should error when requesting in a cooldown', async function() {
    const { requester, receiver } = this.signers
    await expect(
      requester.withContract.request(3, receiver.address, ethers.utils.parseEther('0.05'), this.txURI)
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should approve', async function() {
    const { owner, approver1, approver2, approver3 } = this.signers
  
    await expect(approver1.withContract.approve(1))
      .to.emit(owner.withContract, 'FundsApproved')
      .withArgs(1)
    let tx = await owner.withContract.txs(1)
    expect(tx.approvals).to.equal(1)
    expect(tx.withdrawn).to.equal(false)
    expect(await owner.withContract.isApproved(1)).to.equal(true)

    await expect(approver1.withContract.approve(2))
      .to.emit(owner.withContract, 'FundsApprovedFrom')
      .withArgs(approver1.address, 2)
    tx = await owner.withContract.txs(2)
    expect(tx.approvals).to.equal(1)
    expect(tx.withdrawn).to.equal(false)
    expect(await owner.withContract.isApproved(2)).to.equal(false)

    await expect(approver2.withContract.approve(2))
      .to.emit(owner.withContract, 'FundsApprovedFrom')
      .withArgs(approver2.address, 2)
    tx = await owner.withContract.txs(2)
    expect(tx.approvals).to.equal(2)
    expect(tx.withdrawn).to.equal(false)
    expect(await owner.withContract.isApproved(2)).to.equal(false)

    await expect(approver3.withContract.approve(2))
      .to.emit(owner.withContract, 'FundsApproved')
      .withArgs(2)
    tx = await owner.withContract.txs(2)
    expect(tx.approvals).to.equal(3)
    expect(tx.withdrawn).to.equal(false)
    expect(await owner.withContract.isApproved(2)).to.equal(true)
  })

  it('Should error approving non existent request', async function() {
    const { approver1 } = this.signers
    await expect(
      approver1.withContract.approve(10)
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should not allow duplicate approving', async function() {
    const { approver1 } = this.signers
    await expect(
      approver1.withContract.approve(1)
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should withdraw', async function() {
    const { owner, receiver } = this.signers

    const balance = parseFloat(ethers.utils.formatEther(
      await receiver.getBalance()
    ))

    await expect(owner.withContract.withdraw(1))
      .to.emit(owner.withContract, 'FundsWithdrawn')
      .withArgs(1)

    expect(parseFloat(ethers.utils.formatEther(
      await receiver.getBalance()
    )) - balance).to.be.above(0.049)

    await expect(owner.withContract.withdraw(2))
      .to.emit(owner.withContract, 'FundsWithdrawn')
      .withArgs(2)

    expect(parseFloat(ethers.utils.formatEther(
      await receiver.getBalance()
    )) - balance).to.be.above(5.049)
  })

  it('Should not allow approving already withdrawn tx', async function() {
    const { approver4 } = this.signers
    await expect(approver4.withContract.approve(1)).to.be.revertedWith('InvalidCall()')
  })

  it('Should not allow requests passed the available funds in the contract', async function() {
    const { requester, receiver } = this.signers
    await expect(
      requester.withContract.request(3, 
        receiver.address, 
        ethers.utils.parseEther('20'), 
        this.txURI
      )
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should be able to cancel request', async function() {
    const { requester, receiver, approver1, approver2 } = this.signers
    await requester.withContract.request(3, receiver.address, ethers.utils.parseEther('0.5'), this.txURI)
    let tx = await requester.withContract.txs(3)
    expect(tx.cancelled).to.equal(false)

    await expect(requester.withContract.cancel(3))
      .to.emit(requester.withContract, 'RequestCancelled')
      .withArgs(3)
    tx = await requester.withContract.txs(3)
    expect(tx.cancelled).to.equal(true)

    await requester.withContract.request(4, receiver.address, ethers.utils.parseEther('0.5'), this.txURI)
    
    tx = await requester.withContract.txs(4)
    expect(tx.beneficiary).to.equal(receiver.address)
    expect(tx.amount).to.equal(ethers.utils.parseEther('0.5'))
    expect(tx.approvals).to.equal(0)
    expect(tx.withdrawn).to.equal(false)
    expect(tx.cancelled).to.equal(false)

    await approver1.withContract.approve(4)
    await approver2.withContract.approve(4)
  })

  it('Should error when withdrawing the available funds in the contract', async function() {
    const { 
      owner, 
      approver1, 
      approver2, 
      approver3, 
      approver4, 
      requester, 
      receiver 
    } = this.signers

    await requester.withContract.request(5, 
      receiver.address, 
      ethers.utils.parseEther('15.9'), 
      this.txURI
    )

    await approver1.withContract.approve(5)
    await approver2.withContract.approve(5)
    await approver3.withContract.approve(5)
    await approver4.withContract.approve(5)

    await owner.withContract.withdraw(5)
    
    await expect(
      owner.withContract.withdraw(4)
    ).to.be.revertedWith('InvalidCall()')
  })
})