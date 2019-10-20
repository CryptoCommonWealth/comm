const Comm = artifacts.require('./Comm');

const CommTokenVesting = artifacts.require('./CommTokenVesting');


require('chai')
    .use(require('chai-as-promised'))
    .should();

contract('CommTokenVesting', function ([_, owner, beneficiary]) {

});
