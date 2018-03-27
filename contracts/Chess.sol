/**
 * Chess contract
 * Stores any amount of games with two players and current state.
 * State encoding:
 *    positive numbers for white, negative numbers for black
 *    for details, see
 *    https://github.com/ise-ethereum/on-chain-chess/wiki/Chess-board-representation
 */

import "TurnBasedGame.sol";
import "ChessLogic.sol";
import "Auth.sol";
import "ELO.sol";

contract Chess is TurnBasedGame, Auth {
    using ChessLogic for ChessLogic.State;
    mapping (bytes32 => ChessLogic.State) gameStates;

    using ELO for ELO.Scores;
    ELO.Scores eloScores;

    function getEloScore(address player) constant returns(uint) {
        return eloScores.getScore(player);
    }

    event GameInitialized(bytes32 indexed gameId, address indexed player1, string player1Alias, address playerWhite, uint turnTime, uint pot);
    event GameJoined(bytes32 indexed gameId, address indexed player1, string player1Alias, address indexed player2, string player2Alias, address playerWhite, uint pot);
    event GameStateChanged(bytes32 indexed gameId, int8[128] state);
    event Move(bytes32 indexed gameId, address indexed player, uint256 fromIndex, uint256 toIndex);
    event EloScoreUpdate(address indexed player, uint score);

    function Chess(bool enableDebugging) TurnBasedGame(enableDebugging) {
    }

    /**
     * Initialize a new game
     * string player1Alias: Alias of the player creating the game
     * bool playAsWhite: Pass true or false depending on if the creator will play as white
     */
    function initGame(string player1Alias, bool playAsWhite, uint turnTime) public returns (bytes32) {
        bytes32 gameId = super.initGame(player1Alias, playAsWhite, turnTime);

        // Setup game state
        int8 nextPlayerColor = int8(1);
        gameStates[gameId].setupState(nextPlayerColor);
        if (playAsWhite) {
            // Player 1 will play as white
            gameStates[gameId].playerWhite = msg.sender;

            // Game starts with White, so here player 1
            games[gameId].nextPlayer = games[gameId].player1;
        }

        // Sent notification events
        GameInitialized(gameId, games[gameId].player1, player1Alias, gameStates[gameId].playerWhite, games[gameId].turnTime, games[gameId].pot);
        GameStateChanged(gameId, gameStates[gameId].fields);
        return gameId;
    }

    /**
     * Join an initialized game
     * bytes32 gameId: ID of the game to join
     * string player2Alias: Alias of the player that is joining
     */
    function joinGame(bytes32 gameId, string player2Alias) public {
        super.joinGame(gameId, player2Alias);

        // If the other player isn't white, player2 will play as white
        if (gameStates[gameId].playerWhite == 0) {
            gameStates[gameId].playerWhite = msg.sender;
            // Game starts with White, so here player2
            games[gameId].nextPlayer = games[gameId].player2;
        }

        GameJoined(gameId, games[gameId].player1, games[gameId].player1Alias, games[gameId].player2, player2Alias, gameStates[gameId].playerWhite, games[gameId].pot);
    }

    function move(bytes32 gameId, uint256 fromIndex, uint256 toIndex) notEnded(gameId) public {
        if (games[gameId].timeoutState == 2 &&
           now >= games[gameId].timeoutStarted + games[gameId].turnTime * 1 minutes &&
           msg.sender != games[gameId].nextPlayer) {
            // Just a fake move to determine if there is a possible move left for timeout

            // Chess move validation
            gameStates[gameId].move(fromIndex, toIndex, msg.sender != gameStates[gameId].playerWhite);
        } else {
            if (games[gameId].nextPlayer != msg.sender) {
                throw;
            }
            if(games[gameId].timeoutState != 0) {
                games[gameId].timeoutState = 0;
            }

            // Chess move validation
            gameStates[gameId].move(fromIndex, toIndex, msg.sender == gameStates[gameId].playerWhite);

            // Set nextPlayer
            if (msg.sender == games[gameId].player1) {
                games[gameId].nextPlayer = games[gameId].player2;
            } else {
                games[gameId].nextPlayer = games[gameId].player1;
            }
        }

        // Send events
        Move(gameId, msg.sender, fromIndex, toIndex);
        GameStateChanged(gameId, gameStates[gameId].fields);
    }

    function getCurrentGameState(bytes32 gameId) constant returns (int8[128]) {
       return gameStates[gameId].fields;
    }

    function getWhitePlayer(bytes32 gameId) constant returns (address) {
       return gameStates[gameId].playerWhite;
    }

    function surrender(bytes32 gameId) notEnded(gameId) public {
        super.surrender(gameId);

        // Update ELO scores
        var game = games[gameId];
        eloScores.recordResult(game.player1, game.player2, game.winner);
        EloScoreUpdate(game.player1, eloScores.getScore(game.player1));
        EloScoreUpdate(game.player2, eloScores.getScore(game.player2));
    }

   /* This unnamed function is called whenever someone tries to send ether to the contract */
    function () {
        throw; // Prevents accidental sending of ether
    }
}
