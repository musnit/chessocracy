var DemocraticPlayer1 = artifacts.require("./DemocraticPlayer.sol");
var DemocraticPlayer2 = artifacts.require("./DemocraticPlayer.sol");

module.exports = function(deployer) {
  deployer.deploy(DemocraticPlayer2);
  deployer.deploy(DemocraticPlayer1);

};
