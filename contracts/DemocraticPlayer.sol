pragma solidity 0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

interface Chess {
  function move(bytes32 gameId, uint256 fromIndex, uint256 toIndex) public;
  function initGame(string player1Alias, bool playAsWhite, uint turnTime) public returns (bytes32);
  function joinGame(bytes32 gameId, string player2Alias) public;
  function surrender(bytes32 gameId) public;
}

contract DemocraticPlayer is MintableToken {

  struct Round {
    mapping (bytes32 => uint256) moveVotes;
    mapping (address => bool) addressHasVoted;
    bytes32 winningMoveKey;
    uint256 winningMoveFromIndex;
    uint256 winningMoveToIndex;
  }

  Chess public chess;
  bytes32 public gameId;

  mapping (address => uint256) public staked;
  bool public gameInProgress;

  uint public roundNumber;
  mapping (uint => Round) public rounds;

  function setChessContract(address _chessAddress) external onlyOwner {
    require(!gameInProgress);
    chess = Chess(_chessAddress);
  }

  function initGame() external {
    require(!gameInProgress);
    gameId = chess.initGame("DemocraticPlayer", true, 9999999999999);
    startGame();
  }

  function joinGame(bytes32 _gameId) external {
    require(!gameInProgress);
    gameId = _gameId;
    chess.joinGame(_gameId, "DemocraticPlayer");
    startGame();
  }

  //Owner controlled for now, should maybe be based on a set period of N blocks
  //during which anyone can vote and after which voting stops and anyone can submit.
  function submitMove() external onlyOwner {
    require(gameInProgress);
    Round storage round = rounds[roundNumber];
    roundNumber++;
    chess.move(gameId, round.winningMoveFromIndex, round.winningMoveToIndex);
  }

  function voteMove(uint256 fromIndex, uint256 toIndex) external {
    require(gameInProgress);
    Round storage round = rounds[roundNumber];
    require(!round.addressHasVoted[msg.sender]);
    round.addressHasVoted[msg.sender] = true;
    uint256 senderVotes = staked[msg.sender];
    bytes32 moveKey = keccak256(fromIndex, toIndex);
    round.moveVotes[moveKey] = round.moveVotes[moveKey].add(senderVotes);
    if (round.moveVotes[moveKey] > round.moveVotes[round.winningMoveKey]) {
      round.winningMoveKey = moveKey;
      round.winningMoveFromIndex = fromIndex;
      round.winningMoveToIndex = toIndex;
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

  function startGame() private onlyOwner {
    gameInProgress = true;
    roundNumber = 0;
  }

}
