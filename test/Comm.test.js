const Comm = artifacts.require('./Comm');

const tokens = (n) => ethers(n)

const ethers = (n) => {
  return new web3.utils.BN(web3.utils.toWei(n.toString(), 'ether'));
}

const EVM_REVERT = 'VM Exception while processing transaction: revert';

require('chai')
  .use(require('chai-as-promised'))
  .should();

contract('Common', function([deployer, sender, receiver]) {
	let token;
  const name = 'Crypto Commonwealth';
  const symbol = 'COMM';
  const decimals = '18';
  const totalSupply = tokens(1000000000).toString();


  beforeEach(async () => {
    token = await Comm.new();
  });
	
  describe('deployment', () => {
    it('tracks the name', async () => {
      const result = await token.name();
      result.should.equal(name);
    })

    it('track the totalSupply', async () => {
      const result = await token.totalSupply();
      result.toString().should.equal(totalSupply.toString());
    })

    it('assigns the total supply to deployer', async () => {
      const result = await token.balanceOf(deployer);
      result.toString().should.equal(totalSupply.toString());
    })
  })

  describe('send tokens', () => {
    let amount;
    let result;

    describe('success', () => {
      beforeEach(async () => {
        amount = tokens(10);// 10
        result = await token.transfer(receiver, amount, {from: deployer});
      })

      it('transfer token balance', async () => {
        let balanceOf;
        balanceOf = await token.balanceOf(deployer);
        balanceOf.toString().should.equal(tokens(999999990).toString());
        balanceOf = await token.balanceOf(receiver);
        balanceOf.toString().should.equal(tokens(10).toString());
      })


    })

  })

})
