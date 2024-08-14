// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGuessingGame} from "./interfaces/IGuessingGame.sol";
import {MIN_NUM, MAX_NUM} from "./base/Constants.sol";

contract GuessingGame is IGuessingGame, Ownable {
  Game[] public games;
  uint32 public nextGameId = 0;

  // Constructor
  constructor() Ownable(msg.sender) {
    // Initialization happens here
  }

  // Modifiers declaration
  modifier validGameId(uint32 gameId) {
    if (gameId >= nextGameId) {
      revert GuessingGame__InvalidGameId();
    }
    _;
  }

  modifier nonEndState(uint32 gameId) {
    Game storage game = games[gameId];
    if (game.state == GameState.GameEnd) {
      revert GuessingGame__GameHasEnded();
    }
    _;
  }

  modifier gameStateIn2(uint32 gameId, GameState[2] memory gss) {
    Game storage game = games[gameId];
    if (game.state != gss[0] && game.state != gss[1]) {
      revert GuessingGame__UnexpectedGameState(game.state);
    }
    _;
  }

  modifier oneOfPlayers(uint32 gameId) {
    Game storage game = games[gameId];
    bool found = false;
    for (uint8 i = 0; i < game.players.length; i++) {
      if (game.players[i] == msg.sender) {
        found = true;
        break;
      }
    }
    if (!found) {
      revert GuessingGame__SenderNotOneOfPlayers();
    }
    _;
  }

  modifier gameStateEq(uint32 gameId, GameState gs) {
    Game storage game = games[gameId];
    if (game.state != gs) {
      revert GuessingGame__UnexpectedGameState(game.state);
    }
    _;
  }

  modifier byGameHost(uint32 gameId) {
    Game storage game = games[gameId];
    address host = game.players[0];
    if (host != msg.sender) {
      revert GuessingGame__SenderIsNotGameHost();
    }
    _;
  }

  // Helper functions
  function _updateGameState(uint32 gameId, GameState state) internal validGameId(gameId) nonEndState(gameId) {
    Game storage game = games[gameId];
    game.state = state;

    // Dealing with time recording
    game.lastUpdate = block.timestamp;
    if (state == GameState.GameInitiated) {
      game.startTime = game.lastUpdate;
    } else if (state == GameState.GameEnd) {
      game.endTime = game.lastUpdate;
    }

    emit GameStateUpdated(gameId, state);
  }

  function newGame() external override returns (uint32 gameId) {
    Game storage game = games.push();
    game.players.push(msg.sender);
    gameId = nextGameId++;
    _updateGameState(gameId, GameState.GameInitiated);

    emit NewGame(gameId, msg.sender);
  }

  // IMPROVE: the gameStateIn() modifier code is bad. It is restricted to take
  //   two params.
  function joinGame(uint32 gameId) external override validGameId(gameId) gameStateEq(gameId, GameState.GameInitiated) {
    Game storage game = games[gameId];
    // check the player has not been added to the game
    for (uint8 i = 0; i < game.players.length; i++) {
      if (game.players[i] == msg.sender) {
        revert GuessingGame__PlayerAlreadyJoin(msg.sender);
      }
    }

    game.players.push(msg.sender);
    emit PlayerJoinGame(gameId, msg.sender);
  }

  function startRound(
    uint32 gameId
  ) external override validGameId(gameId) byGameHost(gameId) gameStateIn2(gameId, [GameState.GameInitiated, GameState.RoundEnd]) {
    _updateGameState(gameId, GameState.RoundBid);
    emit GameStarted(gameId);
  }

  function submitBid(
    uint32 gameId,
    bytes32 bid_null_hash,
    bytes32 null_hash
  ) external override validGameId(gameId) oneOfPlayers(gameId) gameStateEq(gameId, GameState.RoundBid) {
    // each player submit a bid. The last player that submit a bid will change the game state
    Game storage game = games[gameId];
    uint8 round = game.currentRound;
    game.bids[round][msg.sender] = Bid(bid_null_hash, null_hash);
    emit BidSubmitted(gameId, round, msg.sender);

    // If all players have submitted bid, update game state
    bool notYetBid = false;
    for (uint i = 0; i < game.players.length; i++) {
      address p = game.players[i];
      if (game.bids[round][p].bid_null_hash == bytes32(0)) {
        notYetBid = true;
        break;
      }
    }

    if (!notYetBid) {
      _updateGameState(gameId, GameState.RoundReveal);
    }
  }

  function revealBid() {
    // each player reveal a bid. The last player that reveal a bid will change the game state
  }

  function endRound() {
    // the average will be cmoputed, the winner will be determined. Update the game state.
  }
}
