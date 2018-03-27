var Chess = artifacts.require("./Chess.sol");
var ChessLogic = artifacts.require("ChessLogic.sol");
var ELO = artifacts.require("ELO.sol");

module.exports = function(deployer) {
  deployer.deploy(ELO);
  deployer.deploy(ChessLogic);

  deployer.link(ChessLogic, Chess);
  deployer.link(ELO, Chess); 
  deployer.deploy(Chess, true, {gas:4000000}); 
};

