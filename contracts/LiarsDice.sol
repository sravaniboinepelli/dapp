// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/// @title Contract for Liars Dice single hand version of the game

contract LiarsDice {

    /// @dev number of dice given initially per player
    uint8 public numSetDice = 6;

    /// @dev number of players who have paid so far
    uint8 public numPaid = 0;

    /// @dev dummy value for random number generation
    uint16 ninfi = 0;

    /// @dev various possible stages of the game
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
        address playeradd;
    }

    /// @dev Winner of the game
    struct finalWinner {
        uint8 playerNo;
        address playeradd;
    } 
    finalWinner public winningPlayer;
  
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
    uint8 public numActivePlayers = 0;

    //uint8[] public numDiceList;

    bool public isSubmitted = false;

    /// @dev current round number
    uint8  numRound=0;
    uint8 public turnOfPlayer;
    
    uint256[] dummyVal;

    /// @dev stores if the game has ended
    uint8 public isGameEnded = 0;

    /// @dev stores the player number whose turn it is currently
    uint256 public currentturnno = 0;

    /// @dev stores the player address whose turn it is currently
    address public currentturn = address(0);

    /// @dev variable used to return faces
    uint256[] Facesreturn;

    /// @dev the amount each player has to pay to play the game.
    uint256  gameCost;

    uint8 callCount=0;
    /// @dev Front end app shows this by concatenating with string player (instead of address show as player 1, player 2 etc)
    uint8  winnerPlayerPos;

    /// @dev stores the information about the current bid
    bidInfo public currentBid;

    /// @dev players list player at pos 0 will strat the first bid and turns go in clock wise direction.
    address payable [] playerList;

    /// @dev Info associated with players for all players 
    mapping(address => PlayerInfo) public players;

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

   
    /// @notice Constructor initialize default values
    constructor ()  public {
        numPlayers = 0;
        gameCost = 1;
        //numDiceList = [0];
        stage = Stages.initial;
        turnOfPlayer = 0;
        currentBid.faceValue = 0;
        currentBid.numDice = 0;
        winnerPlayerPos = 255;
        winningPlayer.playeradd = address(0);
        winningPlayer.playerNo = 255; 
        dummyVal = [0];
    }

    /// @dev function used to set the number of players and number of dice, in addition, shuffles the dice
    /// @param no_players is the the number of players
    /// @param no_dice is the number of dice
    function setPD(uint8 no_players, uint8 no_dice) public {
        numPlayers = no_players;
        isSubmitted = true;
        uint8 j = 0;
        for(j=0;j<no_players;j++){
            players[playerList[j]].numDice = no_dice;
            players[playerList[j]].prevNumDice = no_dice;
            //players[playerList[j]].RollFaces = new uint256 [](numSetDice);
        }
        DiceShuffle();
        numSetDice = no_dice;
    }

    /// @dev function used to update the turn
    /// @return turnOfPlayer which player has to move
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

    /// @dev updates the addresses and facevalues of the player whose turn it is currently
    function updatecurrentturn() internal {
        currentturnno += 1;
        Facesreturn = [0];
        currentturnno %= playerList.length;
        currentturn = playerList[currentturnno];
        if(players[currentturn].inGame == false)
        {
            updatecurrentturn();
        }
    }

    /// @dev generates random number
    /// @param sender is the address of the player
    function random(address sender) private returns(uint){
        ninfi += 1;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,ninfi,sender)));
    }

    /// @dev function that is called when a challenge is made to a player
    function Challenge() public {
        address challengedplayer = currentBid.playeradd;
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
                numActivePlayers -= 1;
            }
        }
        else{
            players[challengedplayer].prevNumDice = players[challengedplayer].numDice;
            players[challengedplayer].numDice -= 1; 
            if(players[challengedplayer].numDice == 0){
                players[challengedplayer].inGame = false;
                numActivePlayers -= 1;
            }
        }
        if(numActivePlayers == 1){
            endGame();
        }
        else {
            Facesreturn = [0];
            currentBid.numDice = 0;
            currentBid.faceValue = 0;
            currentBid.playeradd = address(0);
            DiceShuffle();
        }

    }
    /// @dev function that is called when a bet is made
    /// @param numDice are the number of Dice that are called in the bet
    /// @param faceValue is the the value of the face that is called in the bet
    function Bet(uint8 numDice, uint8 faceValue) public {
        currentBid.numDice = numDice;
        currentBid.faceValue = faceValue;
        currentBid.playeradd = msg.sender;
        updatecurrentturn();
    }

    /// @dev function that is used to shuffle and randomly generate the dice
    function DiceShuffle() public {
        currentturn = playerList[0];
        currentturnno = 0;
        uint8 j = 0;
        for( j = 0; j<playerList.length;j++){
            uint8 i = 0;
            for(i = 0; i < numSetDice; i++){
                if(i>=players[playerList[j]].numDice){
                    players[playerList[j]].RollFaces[i] = 0 ;
                }
                else{
                    players[playerList[j]].RollFaces[i] = (random(msg.sender)%6)+1; //Random Generator
                }
            }
        }
    }

    /// @dev function that sets Facesreturn to the appropriate value
    function setRolledDice() public {
        Facesreturn = players[msg.sender].RollFaces;
    }

    /// @dev function that returns either facesreturn or returns a dummy value
    function getRolledDice() public view returns(uint256 [] memory) {
        if (msg.sender == currentturn)
            return Facesreturn;
        else return dummyVal;
    }

    /// @dev initial payment made by the players
    function initialpay() public payable {
        require(players[msg.sender].exists == false, "Already joined the game");
        require(msg.value >= gameCost, "Not enough money sent to join game");
        playerList.push(msg.sender);
        players[msg.sender].exists = true;
        players[msg.sender].inGame = true;
        players[msg.sender].numDice = numSetDice;
        players[msg.sender].prevNumDice = numSetDice;

        if (players[msg.sender].RollFaces.length == 0){
            players[msg.sender].RollFaces = new uint256 [](numSetDice);
        }
        players[msg.sender].playerPos = (uint8)(playerList.length) -1;
        numActivePlayers +=1;

        if(msg.value > gameCost) {
            players[msg.sender].balance = msg.value - gameCost;
        }
        if(playerList.length == numPlayers){
            stage = Stages.roll;
        }
    }

    /// @dev function to check for application of game rules
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
             loser = currentBid.playeradd;
            //  loserPos = currentBid.playerPos;
             winnerPlayerPos = turnOfPlayer;
         }else {
           loser = playerList[turnOfPlayer];
           loserPos = turnOfPlayer;
        //    winnerPlayerPos = currentBid.playerPos;
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

    /// @dev function that is called when the game has ended
    function endGame() internal {
        uint8 j = 0;
        address payable winner = playerList[0];
        for( j = 0; j<playerList.length;j++){
            if(players[playerList[j]].inGame==true){
                winner = playerList[j];
                winningPlayer.playerNo = j+1;
            }
        }
        winningPlayer.playeradd = winner;
        isGameEnded = 2;
        uint8 returnamount = numPlayers*1;
        winner.transfer(returnamount);

    }
    
}