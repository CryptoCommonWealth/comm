const { expectRevert, time } = require('@openzeppelin/test-helpers');
const Comm = artifacts.require('./Comm');
const CommTokenVesting = artifacts.require('./CommTokenVesting');
const ETH_ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const ONE_HUNDRED_MILLION = 100000000;

require('chai')
    .use(require('chai-as-promised'))
    .should();

contract('CommTokenVesting', function ([_, owner, beneficiary]) {
    let start;
    let cliffDuration;
    let duration;
    let token;
    let tokenVesting;

    beforeEach(async function () {
        // +1 minute so it starts after contract instantiation
        start = (await time.latest()).add(time.duration.minutes(1));
        console.log('start: ', start.toString())
        cliffDuration = time.duration.years(1);
        console.log('cliffDuration: ', cliffDuration.toString())
        duration = time.duration.years(2);
        console.log('duration: ', duration.toString())

        token = await Comm.new();
        tokenVesting = await CommTokenVesting.new(
            beneficiary,
            start,
            cliffDuration,
            duration,
            0,
            0,
            true
        )
    });

    describe('negative tests', async function() {
        it('reverts with a duration shorter than the cliff', async function () {
            expect(cliffDuration > duration, true);

            await expectRevert(
                CommTokenVesting.new(ETH_ZERO_ADDRESS, start, duration, cliffDuration, 0, 0, true, { from: owner }),
                'TokenVesting: beneficiary is the zero address'
            );

            await expectRevert(
                CommTokenVesting.new(beneficiary, start, duration, cliffDuration, 0, 0, true, { from: owner }),
                'TokenVesting: cliff is longer than duration'
            );
        });

        it('reverts immedReleasedRatio is larger than 100000000.', async function() {
            await expectRevert(
                CommTokenVesting.new(beneficiary, start, cliffDuration, duration, ONE_HUNDRED_MILLION + 1, 0, true, { from: owner }),
                'TokenVesting: immedReleasedRatio is larger than 100000000.'
            );
        });

        it('reverts dailyReleasedRatio*_durationInDays is larger than 100000000.', async function() {
            await expectRevert(
                CommTokenVesting.new(beneficiary, start, cliffDuration, duration, 0, ONE_HUNDRED_MILLION, true, { from: owner }),
                'TokenVesting: dailyReleasedRatio*_durationInDays is larger than 100000000.'
            );
        })
    });
});

