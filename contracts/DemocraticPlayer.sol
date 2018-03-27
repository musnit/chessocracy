pragma solidity 0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

interface Chess {
  function submitMove(bytes4 _move) external;
  function initGame() public;
  function joinGame() public;
  function surrender() public;
  function claimWin() public;
  function claimTime() public;
}

contract DemocraticPlayer is MintableToken {

  struct Round {
    mapping (bytes4 => uint256) moveVotes;
    mapping (address => bool) addressHasVoted;
    bytes4 winningMove;
  }

  Chess public chess;

  mapping (address => uint256) public staked;
  bool public gameInProgress;

  uint public roundNumber;
  mapping (uint => Round) public rounds;

  function setGame(address _chessAddress) external onlyOwner {
    chess = Chess(_chessAddress);
  }

  function startGame() external onlyOwner {
    gameInProgress = true;
    roundNumber = 0;
  }

  //Owner controlled for now, should maybe be based on a set period of N blocks
  //during which anyone can vote and after which voting stops and anyone can submit.
  function submitMove() external onlyOwner {
    Round storage round = rounds[roundNumber];
    roundNumber++;
    chess.submitMove(round.winningMove);
  }

  function voteMove(bytes4 _move) external {
    require(gameInProgress);
    Round storage round = rounds[roundNumber];
    require(!round.addressHasVoted[msg.sender]);
    round.addressHasVoted[msg.sender] = true;
    uint256 senderVotes = staked[msg.sender];
    round.moveVotes[_move] = round.moveVotes[_move].add(senderVotes);
    if (round.moveVotes[_move] > round.moveVotes[round.winningMove]) {
      round.winningMove = _move;
    }
  }

  function stake(uint256 _value) external returns (bool) {
    require(!gameInProgress);
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    staked[msg.sender] = staked[msg.sender].add(_value);
    return true;
  }

  function unstake(uint256 _value) external returns (bool) {
    require(!gameInProgress);
    require(_value <= staked[msg.sender]);
    staked[msg.sender] = staked[msg.sender].sub(_value);
    balances[msg.sender] = balances[msg.sender].add(_value);
    return true;
  }

}
