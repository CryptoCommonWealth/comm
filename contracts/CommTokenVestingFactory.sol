pragma solidity ^0.5.8;

import "./CommTokenVesting.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TokenVestingFactory is Ownable {
    mapping(address => CommTokenVesting) public vestings;
    event Created(CommTokenVesting vesting, address indexed sender);
    function create(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _immedReleasedAmount, uint256 _dailyReleasedAmount, bool _revocable) onlyOwner public returns (CommTokenVesting){
        CommTokenVesting vesting = new CommTokenVesting(_beneficiary,_start,_cliff,_duration,_immedReleasedAmount, _dailyReleasedAmount, _revocable);

        emit Created(vesting, msg.sender);
        vestings[_beneficiary]=vesting;
        return vesting;
    }
}
