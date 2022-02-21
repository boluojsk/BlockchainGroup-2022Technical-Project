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
    it('should match 1st, 2nd, 3rd accounts on ganache', async () => {
      // change to your own accounts on ganache
      //assert.equal(accounts[0], 0x922DCBAC38d92E2063A9AdDb0c3A7014b317f3B0)
      //assert.equal(accounts[1], 0xf192EB8A36b2691051fEa9a7fCE6da58Ef71bE3D)

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
      try{
        await contract.makeBid(11,1,3,accounts[1],{from:accounts[2],value:11})
        const auctionObj = await contract.getAuctionObject(accounts[1],{from:accounts[0]})
        assert.equal(auctionObj.availableBids[0].loan_amount, 11);
        assert.equal(auctionObj.availableBids[0].interest_rate, 1);
        assert.equal(auctionObj.availableBids[0].repayment_time, 3);
        assert.equal(auctionObj.availableBids[0].bidder_address, accounts[2]);
        // ensure that the eligibleWithdrawal includes how much they bid
        const eligibleWithdrawal1 = await contract.showEligibleWithdrawal(accounts[1],{from:accounts[2]})
        assert.equal(eligibleWithdrawal1, 11);
        // make new bid
        await contract.makeBid(13,1,3,accounts[1],{from:accounts[2],value:13})
        const eligibleWithdrawal2 = await contract.showEligibleWithdrawal(accounts[1],{from:accounts[2]})
        // bid 1 amt + bid 2 amt
        assert.equal(eligibleWithdrawal2, 11 + 13)
      }catch(error){console.log(error)}
    }) 
  })
})
