const { assert } = require('chai')

const BlindAuction = artifacts.require('./BlindAuction.sol')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('BlindAuction', (accounts) => {
  let contract

  before(async () => {
    contract = await BlindAuction.deployed()
  })

  describe('deployment', async () => {
    it('should match first account on ganache', async () => {
      // change to your own accounts on ganache
      assert.equal(accounts[0], 0x0FD69542cE44e59355e9D2F57a1aABd7c77cebED)
      assert.equal(accounts[1], 0xb04cd5578e69740328930E461926C66519C0a468)

    })
  })
  //account[0] -> owner of auction
  //account[1] -> NFT address
  //other accounts -> bidders from account[2] to account[9]
  describe('sample testing',async () => {
    it('start auction', async () => {
      await contract.startAuction(10,accounts[1],3,{from:accounts[0]})
      const auctionObj = await contract.getAuctionObject(accounts[1],{from:accounts[0]})
      assert.equal(auctionObj.min_loan_amount, 10)
    })
    it('make bid', async () => {
      await contract.makeBid(11,1,3,accounts[1],{from:accounts[2],value:11})
      const auctionObj = await contract.getAuctionObject(accounts[1],{from:accounts[0]})
      assert.equal(auctionObj.availableBids[0].loan_amount, 11);
      assert.equal(auctionObj.availableBids[0].interest_rate, 1);
      assert.equal(auctionObj.availableBids[0].repayment_time, 3);
      assert.equal(auctionObj.availableBids[0].bidder_address, accounts[2]);
      const eligibleWithdrawal = await contract.showEligibleWithdrawal(accounts[1],{from:accounts[2]})
      assert.equal(eligibleWithdrawal, 11);
    })
  })
})
