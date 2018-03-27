contract TurnBasedGame {
    bool debug; // If contract is deployed in debug mode, some debug features are enabled
    modifier debugOnly {
        if (!debug)
            throw;
        _;
    }

    event GameEnded(bytes32 indexed gameId);
    event GameClosed(bytes32 indexed gameId, address indexed player);
    event GameTimeoutStarted(bytes32 indexed gameId, uint timeoutStarted, int8 timeoutState);
    // GameDrawOfferRejected: notification that a draw of the currently turning player
    //                        is rejected by the waiting player
    event GameDrawOfferRejected(bytes32 indexed gameId);
    event DebugInts(string message, uint value1, uint value2, uint value3);

    struct Game {
        address player1;
        address player2;
        string player1Alias;
        string player2Alias;
        address nextPlayer;
        address winner;
        bool ended;
        uint pot; // What this game is worth: ether paid into the game
        uint player1Winnings;
        uint player2Winnings;
        uint turnTime; // in minutes
        uint timeoutStarted; // timer for timeout
        /*
         * -2 draw offered by nextPlayer
         * -1 draw offered by waiting player
         * 0 nothing
         * 1 checkmate
         * 2 timeout
         */
        int8 timeoutState;
    }

    mapping (bytes32 => Game) public games;

    // stack of open game ids
    mapping (bytes32 => bytes32) public openGameIds;
    bytes32 public head;

    // stack of games of players
    mapping (address => mapping (bytes32 => bytes32)) public gamesOfPlayers;
    mapping (address => bytes32) public gamesOfPlayersHeads;

    /**
     * Surrender = unilateral declaration of loss
     */
    function surrender(bytes32 gameId) notEnded(gameId) public {
        if (games[gameId].winner != 0) {
            // Game already ended
            throw;
        }
        if (games[gameId].player1 == msg.sender) {
            // Player 1 surrendered, player 2 won
            games[gameId].winner = games[gameId].player2;
            games[gameId].player2Winnings = games[gameId].pot;
            games[gameId].pot = 0;
        } else if(games[gameId].player2 == msg.sender) {
            // Player 2 surrendered, player 1 won
            games[gameId].winner = games[gameId].player1;
            games[gameId].player1Winnings = games[gameId].pot;
            games[gameId].pot = 0;
        } else {
            // Sender is not a participant of this game
            throw;
        }

        games[gameId].ended = true;
        GameEnded(gameId);
    }

    /**
     * Allows the winner of a game to withdraw their ether
     * bytes32 gameId: ID of the game they have won
     */
    function withdraw(bytes32 gameId) public {
        uint payout = 0;
        if(games[gameId].player1 == msg.sender && games[gameId].player1Winnings > 0) {
            payout = games[gameId].player1Winnings;
            games[gameId].player1Winnings = 0;
            if (!msg.sender.send(payout)) {
                throw;
            }
        }
        else if(games[gameId].player2 == msg.sender && games[gameId].player2Winnings > 0) {
            payout = games[gameId].player2Winnings;
            games[gameId].player2Winnings = 0;
            if (!msg.sender.send(payout)) {
                throw;
            }
        }
        else {
            throw;
        }
    }

    function isGameEnded(bytes32 gameId) public constant returns (bool) {
        return games[gameId].ended;
    }

    modifier notEnded(bytes32 gameId) {
        if (games[gameId].ended) throw;
        _;
    }

    function initGame(string player1Alias, bool playAsWhite, uint turnTime) public returns (bytes32) {
        if (turnTime < 5)
            throw;

        // Generate game id based on player's addresses and current block number
        bytes32 gameId = sha3(msg.sender, block.number);

        games[gameId].ended = false;
        games[gameId].turnTime = turnTime;
        games[gameId].timeoutState = 0;

        // Initialize participants
        games[gameId].player1 = msg.sender;
        games[gameId].player1Alias = player1Alias;
        games[gameId].player1Winnings = 0;
        games[gameId].player2Winnings = 0;

        // Initialize game value
        games[gameId].pot = msg.value * 2;

        // Add game to gamesOfPlayers
        gamesOfPlayers[msg.sender][gameId] = gamesOfPlayersHeads[msg.sender];
        gamesOfPlayersHeads[msg.sender] = gameId;

        // Add to openGameIds
        openGameIds[gameId] = head;
        head = gameId;

        return gameId;
    }

    /**
     * Join an initialized game
     * bytes32 gameId: ID of the game to join
     * string player2Alias: Alias of the player that is joining
     */
    function joinGame(bytes32 gameId, string player2Alias) public {
        // Check that this game does not have a second player yet
        if (games[gameId].player2 != 0) {
            throw;
        }

        // throw if the second player did not match the bet.
        if (msg.value != games[gameId].pot) {
            throw;
        }
        games[gameId].pot += msg.value;

        games[gameId].player2 = msg.sender;
        games[gameId].player2Alias = player2Alias;

        // Add game to gamesOfPlayers
        gamesOfPlayers[msg.sender][gameId] = gamesOfPlayersHeads[msg.sender];
        gamesOfPlayersHeads[msg.sender] = gameId;

        // Remove from openGameIds
        if (head == gameId) {
            head = openGameIds[head];
            openGameIds[gameId] = 0;
        } else {
            for (var g = head; g != 'end' && openGameIds[g] != 'end'; g = openGameIds[g]) {
                if (openGameIds[g] == gameId) {
                    openGameIds[g] = openGameIds[gameId];
                    openGameIds[gameId] = 0;
                    break;
                }
            }
        }
    }

    /* The sender offers the other player a draw. Starts a timeout. */
    function offerDraw(bytes32 gameId) notEnded(gameId) public {
        var game = games[gameId];
        // just the two players currently playing
        if (msg.sender != game.player1 && msg.sender != game.player2)
            throw;
        // only if timeout has not started or is a draw by nextPlayer
        if (game.timeoutState != 0 && game.timeoutState != 2)
            throw;
        // if state = timeout, timeout has to be 2*timeoutTime
        if (game.timeoutState == 2 && now < game.timeoutStarted + 2 * game.turnTime * 1 minutes)
            throw;

        if (msg.sender == game.nextPlayer) {
            game.timeoutState = -2;
        } else {
            game.timeoutState = -1;
        }
        game.timeoutStarted = now;
        GameTimeoutStarted(gameId, game.timeoutStarted, game.timeoutState);
    }

    /*
     * The sender (waiting player) rejects the draw offered by the
     * other (turning / current) player.
     */
    // make sure another move rejects to offer. 
    function rejectCurrentPlayerDraw(bytes32 gameId) notEnded(gameId) public {
        var game = games[gameId];
        // just the two players currently playing
        if (msg.sender != game.player1 && msg.sender != game.player2)
            throw;
        // only if timeout is present
        if (game.timeoutState != -2)
            throw;
        // only not playing player is able to reject a draw offer of the nextPlayer
        if (msg.sender == game.nextPlayer)
            throw;
        game.timeoutState = 0;
        GameDrawOfferRejected(gameId);
    }

    function TurnBasedGame(bool enableDebugging) {
        debug = enableDebugging;
        head = 'end';
    }
}
