const Token = artifacts.require("Comm");

module.exports = function(deployer) {
  deployer.deploy(Token);
};
