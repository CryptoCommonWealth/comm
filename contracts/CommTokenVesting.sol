pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract CommTokenVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;
    bool private _revocable;

    // non-linear params times 10^8
    uint256 private _immedReleasedAmount;
    uint256 private _dailyReleasedAmount;
    uint256 private _isNLReleasable;
    uint256 private _dailyReleasedNLAmount;
    uint256 private _durationInDays;

    uint256 constant oneHundredMillion = 100000000;
    uint256 constant secondsPerDay = 86400;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param immedReleasedAmount non-liner unlock param
     * @param dailyReleasedAmount non-liner unlock param
     * @param revocable whether the vesting is revocable or not
     */
    constructor (address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, uint256 immedReleasedAmount, uint256 dailyReleasedAmount, bool revocable) public {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        require(cliffDuration <= duration, "TokenVesting: cliff is longer than duration");
        require(start.add(duration) > block.timestamp, "TokenVesting: final time is before current time");
        require(duration >= secondsPerDay, "TokenVesting: duration must be over a day at least.");

        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
        _durationInDays = duration.div(secondsPerDay);

        require(immedReleasedAmount <= oneHundredMillion, "TokenVesting: immedReleasedAmount is larger than 100000000.");
        require(dailyReleasedAmount.mul(_durationInDays) <= oneHundredMillion, "TokenVesting: immedReleasedAmount*_durationInDays is larger than 100000000.");

        _immedReleasedAmount = immedReleasedAmount;
        _dailyReleasedAmount = dailyReleasedAmount;
        _isNLReleasable = oneHundredMillion.sub(_immedReleasedAmount).sub(_durationInDays.mul(_dailyReleasedAmount));
        _dailyReleasedNLAmount = _isNLReleasable.div(_durationInDays.mul(_durationInDays).mul(_durationInDays));
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() external view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() external view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() external view returns (uint256) {
        return _duration;
    }

    /**
     * @return the immedReleasedAmount of the token vesting.
    */
    function immedReleasedAmount() external view returns (uint256) {
        return _immedReleasedAmount;
    }

    /**
    * @return the dailyReleasedAmount of the token vesting.
    */
    function dailyReleasedAmount() external view returns (uint256) {
        return _dailyReleasedAmount;
    }

    /**
    * @return the isNLReleasable value of the token vesting.
    */
    function isNLReleasable() external view returns (uint256) {
        return _isNLReleasable;
    }

    /**
    * @return the dailyReleasedNLAmount of the token vesting.
    */
    function dailyReleasedNLAmount() external view returns (uint256) {
        return _dailyReleasedNLAmount;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function revocable() external view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address token) external view returns (uint256) {
        return _released[token];
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked(address token) external view returns (bool) {
        return _revoked[token];
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[address(token)], "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function _releasableAmount(IERC20 token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
            return totalBalance;
        } else if (_immedReleasedAmount == 0 && _dailyReleasedAmount == 0) {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        } else {
            uint256 daysPassed = block.timestamp.sub(_start).div(secondsPerDay);
            uint256 amount0 = totalBalance.mul(_immedReleasedAmount).div(oneHundredMillion);
            uint256 amount1 = totalBalance.mul(_dailyReleasedAmount).mul(daysPassed).div(oneHundredMillion);
            uint256 amount2 = totalBalance.mul(_dailyReleasedNLAmount.mul(daysPassed.mul(daysPassed).mul(daysPassed))).div(oneHundredMillion);
            uint256 vestedAmount = amount0.add(amount1).add(amount2);
            return totalBalance < vestedAmount ? totalBalance : vestedAmount;
        }
    }
}
