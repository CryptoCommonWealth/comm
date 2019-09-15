const Comm = artifacts.require('./Comm');

require('chai')
  .use(require('chai-as-promised'))
  .should();

contract('Common', function() {
	let token;
  const name = 'Crypto Commonwealth';
  const symbol = 'COMM';
  const decimals = '18';


  beforeEach(async () => {
    token = await Comm.new();
  });
	
	describe('deployment', () => {
    it('tracks the name', async () => {
      const result = await token.name();
      result.should.equal(name);
    })
  })

})