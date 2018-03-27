var DemocraticPlayer1 = artifacts.require("./DemocraticPlayer.sol");
var DemocraticPlayer2 = artifacts.require("./DemocraticPlayer.sol");
var chess = artifacts.require("./Chess.sol");

contract('DemocraticPlayer', function(accounts) {
    var owner = web3.eth.accounts[0];
    var player1 = web3.eth.accounts[1];
    var player2 = web3.eth.accounts[2];
    var player3 = web3.eth.accounts[3];

    it("should mint tokens to player 1", function() {
      return DemocraticPlayer1.deployed().then(function(instance) {
        instance.mint(player1, 100 , {from:owner}).then(function (res) {          
          instance.balanceOf.call(player1).then(function (balance) { 
            assert.equal(balance, 100, "failed to mint the correct number of tokens for Player 1");
            var staked1 = instance.stake(100, { from:player1});
          });
        });
      });
    });

    it("should mint tokens for player 2, player 3", function () { 
      return DemocraticPlayer2.deployed().then(function(instance) {
        instance.mint(player2, 201 , {from:owner}).then(function (res) {
          instance.mint(player3, 100 , {from:owner}).then(function (res) {
            instance.balanceOf.call(player2).then(function (balance2) { 
              instance.balanceOf.call(player3).then(function (balance3) {
                assert.equal(balance2, 201, "failed to mint the correct number of tokens for Player 1");
                assert.equal(balance3, 100, "failed to mint the correct number of tokens for Player 1");
                var staked2 = instance.stake(201, { from:player2}); 
                var staked3 = instance.stake(100, { from:player3});
                //Promise.all( staked2, staked3).then(function (res)  { 
                //  console.log(res); 
                //}); 
              });
            });
          });
        });
      });
    })


    it("setup game", function () { 
      return DemocraticPlayer1.deployed().then(function(p1) {
          return chess.deployed().then(function(board) { 
            p1.initGame(board.address, {from:owner}).then( function (res) { 
              var gameId = p1.gameId.call();
              console.log("test", gameId); 
              return DemocraticPlayer2.deployed().then(function(p2) {
                p2.joinGame(gameId, {from:owner}).then(function(res) { 
                  console.log(res);
                });
              });
            });
          });
      });
    });

    it("make first move", function () { 
      return DemocraticPlayer1.deployed().then(function(team1) {
        team1.voteMove(9, 17, {from: player1}).then(function(res) { 
          //team1.submitMove({from:owner}); 
        });
      });
    });



    

});
