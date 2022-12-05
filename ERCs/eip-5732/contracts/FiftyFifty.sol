// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {IERC_COMMIT_CORE} from "./IERC5732.sol";

/// @title  IFiftyFiftyEvents
/// @notice The interface for the events that may be emitted from FiftyFifty.
interface IFiftyFiftyEvents {
    /// @notice all the possible ways a game can end once a bet has been placed.
    enum GameEndReason {
        REVEAL,
        TIMEOUT,
        CANCEL
    }

    event BetPlaced(uint256 indexed gameId, uint256 bet, address committer, bytes32 commitment);
    event BetMatched(uint256 indexed gameId, bool choice, address guesser);
    event GameEnded(uint256 indexed gameId, GameEndReason reason, address winner);
}

/// @title  IFiftyFiftyTypes
/// @notice The types used in FiftyFifty.
interface IFiftyFiftyTypes {
    struct Game {
        bytes32 commitment;
        uint256 bet;
        uint256 expiration;
        address payable committer;
        address payable guesser;
        bool guess;
        bool ended;
    }
}

/// @title  IFiftyFifty
/// @author Matt Stam (@mattstam)
/// @notice FiftyFifty is a cointoss-style game where a committer commits to 1 of 2
///         choices, and any guesser can match their bet to see if they can guess
///         the same choice. Winner takes all.
/// @dev    Errors `IFiftyFiftyErrors`, Events `IFiftyFiftyEvents`, and Types `IFiftyFiftyTypes`
///         are seperated in different interfaces unit testing purposes.
///
///         This is NOT ready for production use. It is a proof of concept. There is a known
///         attack vector the committer can frontrun the guesser if they are about to lose.
interface IFiftyFifty is IFiftyFiftyEvents, IFiftyFiftyTypes, IERC_COMMIT_CORE {
    /// @notice Creates a new game, and sets committer with their commit and the bet.
    /// @param commitment The commitment as a hash of the choice and salt.
    /// @dev GameID for the game will be the next incremented count. 0 value bets are not allowable.
    function commit(bytes32 commitment) external payable;

    /// @notice Allows a guesser to bet if they are able to guess the same.
    /// @param gameId The id of the game to match the bet on. The msg.value must match
    ///     the bet amount of the game.
    /// @param choice The choice the guesser is guessing.
    /// @dev Games need to be expirable, otherwise committer's can just see what guesser's
    ///     chose and never reveal if their bet wouldn't win.
    function matchBet(uint256 gameId, bool choice) external payable;

    /// @notice Allows the committer to cancel their bet if no one has matched it yet.
    /// @param gameId The id of the game to cancel.
    function cancelBet(uint256 gameId) external;

    /// @notice Allows the committer to reveal their choice and end the game. Depending on if the
    ///     guesser guessed the choice, the winner will get transfered the bet amounts.
    /// @param gameId The id of the game to reveal.
    /// @param choice The choice the committer chose.
    /// @param salt The secret salt that was used to hash the choice and create the commitment.
    /// @dev The committer will only ever be incentivized to call this function if they win,
    ///     because otherwise they can will let guesser call timeout and pay gas for it.
    function reveal(
        uint256 gameId,
        bool choice,
        bytes32 salt
    ) external;

    /// @notice Allows the guesser to call timeout if the committer doesn't reveal in time.
    /// @param gameId The id of the game to timeout.
    function timeoutBet(uint256 gameId) external;

    /// @notice Returns the total number of games.
    /// @return count The total number of games.
    function getGameCount() external view returns (uint256 count);

    /// @notice Returns the game with the given ID.
    /// @param gameId The ID of the game to get.
    /// @return game The game with the given ID.
    function getGame(uint256 gameId) external view returns (Game memory game);
}

contract FiftyFifty is IFiftyFifty {
    uint256 private gameCount;
    uint256 private expirationTimeout;
    mapping(uint256 => Game) private games;

    constructor(uint256 _expirationTimeout) {
        expirationTimeout = _expirationTimeout;
    }

    /// @inheritdoc IFiftyFifty
    function commit(bytes32 _commitment) external payable {
        require(msg.value > 0, "cannot bet with 0 value");

        gameCount++;

        games[gameCount].committer = payable(msg.sender);
        games[gameCount].commitment = _commitment;
        games[gameCount].bet = msg.value;

        emit BetPlaced(gameCount, msg.value, msg.sender, _commitment);
    }

    /// @inheritdoc IFiftyFifty
    function cancelBet(uint256 _gameId) external {
        require(games[_gameId].ended == false, "game already ended");
        require(msg.sender == games[_gameId].committer, "cancellable only by committer");
        require(games[_gameId].guesser == address(0), "cancellable only if guesser not set");

        games[_gameId].ended = true;
        games[_gameId].committer.transfer(games[_gameId].bet);

        emit GameEnded(_gameId, GameEndReason.CANCEL, games[_gameId].committer);
    }

    /// @inheritdoc IFiftyFifty
    function matchBet(uint256 _gameId, bool _choice) public payable {
        require(games[_gameId].ended == false, "game already ended");
        require(games[_gameId].guesser == address(0), "may only place bet if nobody else has");
        require(msg.value == games[_gameId].bet, "bet amount does not match");

        games[_gameId].guesser = payable(msg.sender);
        games[_gameId].guess = _choice;
        games[_gameId].expiration = block.timestamp + 7 days;

        emit BetMatched(_gameId, _choice, msg.sender);
    }

    /// @inheritdoc IFiftyFifty
    function reveal(
        uint256 _gameId,
        bool _choice,
        bytes32 _salt
    ) public {
        require(games[_gameId].ended == false, "game already ended");
        require(
            games[_gameId].guesser != address(0),
            "cannot reveal before anyone has matched bet"
        );
        require(
            keccak256(abi.encodePacked(_choice, _salt)) == games[_gameId].commitment,
            "reveal doesn't match commit"
        );

        games[_gameId].ended = true;

        if (games[_gameId].guess == _choice) {
            games[_gameId].guesser.transfer(games[_gameId].bet * 2);
            emit GameEnded(_gameId, GameEndReason.REVEAL, games[_gameId].guesser);
        } else {
            games[_gameId].committer.transfer(games[_gameId].bet * 2);
            emit GameEnded(_gameId, GameEndReason.REVEAL, games[_gameId].committer);
        }
    }

    /// @inheritdoc IFiftyFifty
    function timeoutBet(uint256 _gameId) public {
        require(games[_gameId].ended == false, "game already ended");
        require(block.timestamp > games[_gameId].expiration, "game hasn't expired");

        games[_gameId].ended = true;
        games[_gameId].guesser.transfer(games[_gameId].bet * 2);

        emit GameEnded(_gameId, GameEndReason.TIMEOUT, games[_gameId].guesser);
    }

    /// @inheritdoc IFiftyFifty
    function getGameCount() public view returns (uint256) {
        return gameCount;
    }

    /// @inheritdoc IFiftyFifty
    function getGame(uint256 _gameId) public view returns (Game memory) {
        return games[_gameId];
    }
}
