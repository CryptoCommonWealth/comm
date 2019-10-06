# comm
Crypto Commonwealth

# Setup
Tests need node v8.0.0 or higher, as they depend on async/await functionality. Interacting with eth is very async-y so await makes it much easier to write tests.
Depends on truffle and testrpc for testing.

install truffle:
```npm install -g truffle```

install ganache-cli:
```npm install -g ganache-cli```

install project npm dependencies:
```npm install```

# Testing
All tests are run with:
```truffle tests```

### ERC20 compatible
The COMM implements the ERC20 interface.

### Minting/Burning
Tokens can be minted or burned on demand. The contract supports having multiple minters simultaneously.

### Ownable
The contract has an Owner, who can change the `owner`.

### TokenVesting
A token holder contract that can release its token balance gradually like a typical vesting scheme, with a cliff and vesting period. 
Optionally revocable by the owner.
See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/drafts/TokenVesting.sol
