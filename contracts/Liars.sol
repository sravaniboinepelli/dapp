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
        roll,
        bid,
        bid_challenge,
        challenge,
        endGame
    }


    /// @dev player bids by specifying the face value  and the number of dice with that face  value
    struct bidInfo {
        uint8 faceValue;
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
         uint256 [] RollFaces;
    }

    /// @dev All the money from will be tranfered to this account.
    address payable deployer = msg.sender;

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

     event BidInfo(
        uint256 _bidFaceValue,
        uint8 _bidNumDice,
        uint8 _newNumDice,
        uint256 _newFaceValue
    );

      event InitialPay(
        address sender,
        uint8 info1,
        bool exist 
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

        numPlayers = 2;
        numSetDice = 2;

    }

    function setPD(uint8 no_players, uint8 no_dice) public {
        numPlayers = no_players;
        numSetDice = no_dice;
    }

    function updateTurn()  internal returns(uint8) {
        if( numActivePlayers == 1){
            turnOfPlayer = 255;
            return turnOfPlayer;
        }
        uint8 origTurn = turnOfPlayer;
        turnOfPlayer += 1;
        if(turnOfPlayer >= numPlayers){
           turnOfPlayer = 0; 
        }
        if(turnOfPlayer == origTurn){
           turnOfPlayer = 255; 
        }
        while(playerList[turnOfPlayer] == address(0)){
            turnOfPlayer += 1;

            if (turnOfPlayer >= numPlayers){
                turnOfPlayer = 0;
            }
            if(turnOfPlayer == origTurn){
               turnOfPlayer = 255; 
               break;
            }
        }
        
        return turnOfPlayer;
    }
    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    function Challenge() public {
        address challengedplayer = playerList[currentBid.playerPos];
        uint8 j = 0;
        uint16 facecount = 0;
        uint8 face = currentBid.faceValue;
        for( j =0; j<playerList.length; j++){
            uint8 i = 0;
            for(i = 0; i<players[playerList[j]].RollFaces.length; i++){
                if(players[playerList[j]].RollFaces[i]==face)
                    facecount += 1;
            }
        }
        if(facecount >= currentBid.numDice){
            players[msg.sender].prevNumDice = players[msg.sender].numDice;
            players[msg.sender].numDice -= 1; 
            if(players[msg.sender].numDice == 0){
                players[msg.sender].inGame = false;
            }
        }
        else{
            players[challengedplayer].prevNumDice = players[challengedplayer].numDice;
            players[challengedplayer].numDice -= 1; 
            if(players[challengedplayer].numDice == 0){
                players[challengedplayer].inGame = false;
            }
        }

    }
    function Bet(uint8 numDice, uint8 faceValue) public {
        currentBid.numDice = numDice;
        currentBid.faceValue = faceValue;
        currentBid.playerPos = players[msg.sender].playerPos;
    }

    function DiceShuffle() public {
        uint8 j = 0;
        for( j = 0; j<playerList.length;j++){
            uint8 i = 0;
            for(i = 0; i < numSetDice; i++){
                if(i>players[playerList[j]].numDice){
                    players[playerList[j]].RollFaces[i] = 255 ;
                }
                else{
                    players[playerList[j]].RollFaces[i] = (random()%6)+1; //Random Generator
                }
            }
        }
    }
    
    function getRolledDice() public view returns(uint256 [] memory) {
        PlayerInfo storage info = players[msg.sender];
        return info.RollFaces;
    }

    function getRolledDice2() public view  returns(uint256) {
        PlayerInfo storage info = players[msg.sender];
        return info.RollFaces[0];
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

        if (info.RollFaces.length == 0){
            info.RollFaces = new uint256 [](numSetDice);
        }
        info.playerPos = (uint8)(playerList.length) -1;
        numActivePlayers +=1;

        if(msg.value > gameCost) {
            info.balance = msg.value - gameCost;
        }
        if(playerList.length == numPlayers){
            stage = Stages.roll;
        }
        emit InitialPay(msg.sender, info.numDice, info.exists);
    }
    /// @notice  Fallback function to receive any transfers
    receive() external payable {     
    }

    function applyGameRules() internal {
         address loser;
         uint8 loserPos;
         uint8 numBidFaceFaluesInRoll = rollFaceValues[currentBid.faceValue];

         /// one is wildcard and count towards current bid face value. Do that if bid is not on wildcard value.
         if (currentBid.faceValue != 1) {
            numBidFaceFaluesInRoll += rollFaceValues[1]; 
         }
         /// if we don't have atleast the current bid number of dices then bidder is loser
         if(numBidFaceFaluesInRoll < currentBid.numDice){
             loser = playerList[currentBid.playerPos];
             loserPos = currentBid.playerPos;
             winnerPlayerPos = turnOfPlayer;
         }else {
           loser = playerList[turnOfPlayer];
           loserPos = turnOfPlayer;
           winnerPlayerPos = currentBid.playerPos;
         }
         players[loser].prevNumDice = players[loser].numDice;
         players[loser].numDice -= 1;
         numRound +=1;

         if(players[loser].numDice == 0){
            players[loser].inGame = false;
            // nullify this player so updateTurn will go to validate player
            playerList[players[loser].playerPos] == address(0); 
            numActivePlayers -=1;
            updateTurn();
         }else {
             turnOfPlayer = loserPos; //loser still in game he starts the next round
         }
         
    }
    
}