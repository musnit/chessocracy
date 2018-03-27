var DemocraticPlayer = artifacts.require("./DemocraticPlayer.sol");

module.exports = function(deployer) {
  deployer.deploy(DemocraticPlayer);
};
