// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/// @title Contract for Liars Dice single hand version of the game

contract Liars {

    /// @dev number of dice given initially per player
    uint8 public numSetDice = 5;
    uint8 public numPaid = 0;
    enum Stages
    {
        initial,
        // roll,
        receiveHashedRoll,
        bid,
        bid_challenge,
        challenge,
        receiveRevealedRoll,
        endGame
    }


    /// @dev player bids by specifying the face value  and the number of dice with that face  value
    struct bidInfo {
        uint256 faceValue;
        uint8 numDice;
        uint8 playerPos;
    }

    /// @dev  exists: used to see if player joined the game status will be true till he withdraws any balance owed to him
    /// @dev  inGame: used to see if player lost all his dice and out of the game
    /// @dev  numDice: number of dice player currently posses
    /// @dev  balance: player account balance in wei
    /// @dev  concealedRollFaces: player's roll face values in current round for each of his dice as hash(before challenged)
    /// @dev  revealedRollFaces: player's roll face values in current round for each of his dice(after challenge)
  
    struct PlayerInfo {
         bool exists;
         bool inGame;
         uint8 numDice;
         uint8 prevNumDice;
         uint8 playerPos;    
         uint256 balance; 
         bytes32 [] concealedRollFaces;
         uint256 [] revealedRollFaces;
    
    }
    /// @dev All the money from will be tranfered to this account.
    address payable deployer = msg.sender;

    /// @dev app fron end can check this and call functions to other players reveled dice so 
    /// that they can  be diplayed to player
    bool revealUpdateReady = false;

    /// @dev number of players that need to be join to start the game
    uint8 public numPlayers =2;
    /// @dev number of players that are still in the game
    uint8 public numActivePlayers;
    /// @dev current round number
    uint8  numRound=0;
    uint8  turnOfPlayer;
    /// @dev the amount each player has to pay to play the game.
    uint256  gameCost;

    uint8 callCount=0;

    /// @dev Front end app shows this by concatenating with string player (instead of address show as player 1, player 2 etc)
    uint8  winnerPlayerPos;
    bidInfo currentBid;

    /// @dev players list player at pos 0 will strat the first bid and turns go in clock wise direction.
    address [] playerList;

    /// @dev Info associated with players for all players 
    mapping(address => PlayerInfo) players;

    /// @dev Current stage of the game, fron end apps should call appropriate functions based on stage and display 
    /// relavent info to players like showing other players dice after challenge, Ask users to roll, bid/challenge
    /// (in addition to getting the turn info)
    Stages stage;


    /// @dev stores the number of dice with that face value, updated after getting unHashed face value from each player
    mapping(uint256 => uint8)rollFaceValues;

    event WithDrewMoney(
        address indexed _from,
        uint256 value

    );
     event RecvHashedRoll(
        address indexed _from,
        bytes32 _value1,
        bytes32 _value2
    );
    event SendNonHashedRoll(
        address indexed _from,
        uint256 _value,
        uint256 _secret
    );
     event BidInfo(
        uint256 _bidFaceValue,
        uint8 _bidNumDice,
        uint8 _newNumDice,
        uint256 _newFaceValue
    );

   
    /// @notice Constructor initialize default values
    constructor ()   {
        numPlayers = 0;

        numActivePlayers = 0;
        gameCost = 1;

        stage = Stages.initial;
        turnOfPlayer = 0;
        currentBid.faceValue = 0;
        currentBid.numDice = 0;
        winnerPlayerPos = 255;

    }

    function setPlayer(uint8 no_players) public {
        numPlayers = no_players;
    }

   function setDice(uint8 no_dice) public {
        numSetDice = no_dice;
    }

    function initialpay() public payable {
        require(players[msg.sender].exists == false, "Already joined the game");
        require(msg.value >= gameCost, "Not enough money sent to join game");
        PlayerInfo storage info = players[msg.sender];
        playerList.push(msg.sender);
        info.exists = true;
        info.inGame = true;
        info.numDice = numSetDice;
        info.prevNumDice = numSetDice;
        if (info.concealedRollFaces.length == 0){
            info.concealedRollFaces = new bytes32 [](numSetDice);
        }
        if (info.revealedRollFaces.length == 0){
            info.revealedRollFaces = new uint256 [](numSetDice);
        }
        info.playerPos = (uint8)(playerList.length) -1;
        numActivePlayers +=1;

        
        if(msg.value > gameCost) {
            info.balance = msg.value - gameCost;
        }
        if(playerList.length == numPlayers){
            stage = Stages.receiveHashedRoll;
        }
    }
    /// @notice  Fallback function to receive any transfers
    receive() external payable {     
    }
    
}