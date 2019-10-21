const { expectRevert, time } = require('@openzeppelin/test-helpers');
const Comm = artifacts.require('./Comm');

const CommTokenVesting = artifacts.require('./CommTokenVesting');

require('chai')
    .use(require('chai-as-promised'))
    .should();

contract('CommTokenVesting', function ([_, owner, beneficiary]) {
    beforeEach(async function () {
        // +1 minute so it starts after contract instantiation
        this.start = (await time.latest()).add(time.duration.minutes(1));
        this.cliffDuration = time.duration.years(1);
        this.duration = time.duration.years(2);
    });

    it('reverts with a duration shorter than the cliff', async function () {
        const cliffDuration = this.duration;
        const duration = this.cliffDuration;
        expect(cliffDuration > duration, true);

        await expectRevert(
            CommTokenVesting.new(beneficiary, this.start, cliffDuration, duration, 0, 0, true, { from: owner }),
            'TokenVesting: cliff is longer than duration'
        );
    });
});
