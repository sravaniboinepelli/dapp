// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/// @title Contract for Liars Dice single hand version of the game

contract LiarsDice {

    /// @dev number of dice given initially per player
    uint8 constant numSetDice = 5;
    
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
    uint8 numPlayers =2;
    /// @dev number of players that are still in the game
    uint8 numActivePlayers;
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
    /// @param noOfPlayers: number of players needed to start the game
    /// @param cost: amount of wei that each player should pay to play game
    constructor (uint8 noOfPlayers, uint256 cost)   {
        numPlayers = noOfPlayers;

        numActivePlayers = 0;
        gameCost = cost;

        stage = Stages.initial;
        turnOfPlayer = 0;
        currentBid.faceValue = 0;
        currentBid.numDice = 0;
        winnerPlayerPos = 255;

    }

    /// @notice Function returns the amount present in the contract address balance. 
    /// @return returns conntract balance
    function balanceof() external view returns(uint){
        
        return address(this).balance;
    }
    /// @notice Function Front end app call to see number of players that are still in the game 
    /// @return returns number of players currently  in the game
    function getNumActivePlayers() external view returns(uint8){
        
        return numActivePlayers;
    }
    /// @notice Function Front end app call to diplay current round number .
    /// @return returns round number.
    function getCurrentRound() external view returns(uint8){
        
        return numRound;
    }
    /// @notice Function Front end app call to check the turn.
    /// @return returns if its this player turn. Based on this app should show bid/challenge options to player.
    function ismyTurn() external view returns(bool){
        
        if (turnOfPlayer == 255){
           return false;
        }
        if (players[msg.sender].inGame == true){
            return (players[msg.sender].playerPos == turnOfPlayer);
        }
        return false;
    }
    /// @notice Function Front end app call to diplay amount player has to pay to enter the game.    
    /// @return returns amount in wei 
    function getGameCost() external view returns(uint256){
        
        return gameCost;
    }

    /// @notice Function Front end app call this function to see if all the players 
    /// revealed their roll after a challenge. And can call getActivePlayerLIst and getPlayerReveal to
    /// update dashboard.
    /// @return returns True or false 
    function isRevealUpdateReady() external view returns(bool){
        
        return revealUpdateReady;
    }
    /// @notice Function Front end app call this function to show winner.
    /// shows this by concatenating with string player (instead of address, player 1 , player 2 will be shown)
    /// @return winnerId: return current round winner. when single player is left, this contains game winner.
    /// value 255 should be read as None.
    function getWinnerPlayerId() external view returns(uint8 ){
        return winnerPlayerPos;
    }
    /// @notice Function Front end app call this function to get current bid information
    /// @return faceValue: dice face value bid by player numDice: number of dice with that face value
    /// playerId: id of the palyer from whom this bid was received.
    function getCurrentBidInfo() external view returns(uint256, uint8, uint8){
        // uint256 faceValue1 = currentBid.faceValue;
        // uint8 numDice1 = currentBid.numDice;
        // return (faceValue1, numDice1);
        return (currentBid.faceValue, currentBid.numDice, currentBid.playerPos);
    }
    /// @notice Function Front end app call to get game stage.
    /// @return stage: returns current stage of the game as enum.
    ///  initial = 0, receiveHashedRoll=1,bid =2,bid_challenge= 3,
    /// challenge=4,receiveRevealedRoll=5,endGame=6
    function getGameStage() external view returns(Stages ){
        return (stage);
    }
    
    /// @dev Validates if a perticuler function can be called at a given stage of the game
    /// @dev _stage:  list of stages in which a perticuler function call is allowed
    modifier atStage(Stages [2] memory _stage)
    {
        bool validStage = false;
        for (uint8 i =0; i<_stage.length; i++){
            if(stage == _stage[i]){
                validStage = true;
                break;
            }
        }
        require
        (
            validStage == true ,
            "Function cannot be called at this time."
        );
        _;
    }

    /// @dev After a player bids/challenges determines who would be the next player allowed to bid/challenge.
    /// PlayerList an array of address is used as a circuler buffer to determine the turn. If a perticuler player
    /// at a position is eliminated from game then address is set to 0. If we ended up wit same position 
    /// as original position that means all other players are eliminated and that was marked with a high number 255.
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

    /// @dev Function to check if revealed face values matches with hashed values sent before
    function validateReveal(uint256 [] memory faceValue, uint256 secret, bytes32 [] memory hashedVal) pure internal returns(bool) {
        bool validRoll = true;
        uint8 i =0;
        for (i=0; i<faceValue.length; i++){
            if (hashedVal[i] != getHash(faceValue[i], secret)){
                validRoll = false;
                break;
            }
        }
        if (i == 0) {
            return false;
        }
       
        return validRoll;         
    }

    /// @dev Function to check if bid came as per current rules i.e increase face value or increase in number of dices 
    /// with same face value or increase in both. 
    /// currently no penalty for sending invalid bid. simply he won't be the person that wins/looses based on the 
    /// next person's challenge result.
    function validateAndSaveBid(uint256 faceValue, uint8 numDice)  internal returns(bool) {
        bool validBid = false;
        if (currentBid.faceValue < faceValue){
           validBid = true;
        }
        if (currentBid.numDice < numDice){
           validBid = true;
        }
        emit BidInfo(currentBid.faceValue, currentBid.numDice, numDice, faceValue );
        if (validBid){
            currentBid.faceValue = faceValue;
            currentBid.numDice = numDice;     
        }
        return validBid;         
    }
     /// @dev Function to determine looser based on reveled rolls of all players and by considering one as wildcard
     /// looser will loose one dice and starts the next round. If he looses all dice then next player will start the round.
    function applyGameRules()  internal  {
         address looser;
         uint8 looserPos;
         uint8 numBidFaceFaluesInRoll = rollFaceValues[currentBid.faceValue];

         /// one is wildcard and count towards current bid face value. Do that if bid is not on wildcard value.
         if (currentBid.faceValue != 1) {
            numBidFaceFaluesInRoll += rollFaceValues[1]; 
         }
         /// if we don't have atleast the current bid number of dices then bidder is looser
         if(numBidFaceFaluesInRoll < currentBid.numDice){
             looser = playerList[currentBid.playerPos];
             looserPos = currentBid.playerPos;
             winnerPlayerPos = turnOfPlayer;
         }else {
           looser = playerList[turnOfPlayer];
           looserPos = turnOfPlayer;
           winnerPlayerPos = currentBid.playerPos;
         }
         players[looser].prevNumDice = players[looser].numDice;
         players[looser].numDice -= 1;
         numRound +=1;

         if(players[looser].numDice == 0){
            players[looser].inGame = false;
            // nullify this player so updateTurn will go to validate player
            playerList[players[looser].playerPos] == address(0); 
            numActivePlayers -=1;
            updateTurn();
         }else {
             turnOfPlayer = looserPos; //looser still in game he starts the next round
         }
         
    }

     /// @notice Players join by calling joinGame by sending the gameCost money in msg.value
    function joinGame () public payable  atStage([Stages.initial, Stages.initial]) {
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

    /// @notice front end app should call this function when stage is receiveHashedRoll after making player roll the dice
    /// @param hashed: hashed values of player's  all dice face values.
    function recvHashedRoll(bytes32 [] memory hashed) public  atStage([Stages.receiveHashedRoll, Stages.receiveHashedRoll]) {
        // emit RecvHashedRoll(msg.sender, hashed[0], hashed[1]);
        for(uint8 i=0; i<hashed.length; i++){
           emit RecvHashedRoll(msg.sender, hashed[i], hashed[i]);
        }
        require(players[msg.sender].inGame == true, "You are not part of the game");
        require(players[msg.sender].numDice == hashed.length, "Please send all your dice values");
        
        for(uint8 i=0; i<hashed.length; i++){
            players[msg.sender].concealedRollFaces[i] = hashed[i];
        }
        revealUpdateReady = false;
        players[msg.sender].prevNumDice = players[msg.sender].numDice;
        callCount +=1;
        if(callCount == numActivePlayers){
            stage = Stages.bid;
            callCount = 0;
            currentBid.faceValue = 0;
            currentBid.numDice = 0;
        }

    }

    /// @notice front end app should call this function when the stage is bid or bid_challenge 
    /// to send the bid from the player who got the current turn.
    /// @param faceValue: dice face value
    /// @param numDice: number of dice in the current game wit that face value.
    function sendBid(uint8 faceValue, uint8 numDice) public  atStage([Stages.bid, Stages.bid_challenge]) returns(bool) {

        require(players[msg.sender].inGame == true, "You are not part of the game");
        require(playerList[turnOfPlayer] == msg.sender, "Not your turn to bid");
        bool result = validateAndSaveBid(faceValue, numDice);
        if (result == true) {
            currentBid.playerPos = turnOfPlayer;
            stage = Stages.bid_challenge;
            updateTurn();
        }
        return result;
        // return true;


    }

    /// @notice front end app should call this function when the stage is bid_challenge 
    /// if player opted to challenge previous bid 
    function sendChallenge() public  atStage([Stages.bid_challenge, Stages.bid_challenge]) {

        require(players[msg.sender].inGame == true, "You are not part of the game");
        require(playerList[turnOfPlayer] == msg.sender, "Not your turn");
        stage = Stages.challenge;
    }

    /// @notice front end app should call this function when the stage is challenge
    /// to reveal all the dice face values of current roll.
    /// @param faceValue: all dice face values
    /// @param secret: secret used to come up with hashed value sent before.
    function sendNonHashedRoll(uint256 [] memory faceValue, uint256 secret) public  atStage([Stages.challenge, Stages.challenge]) {
        emit SendNonHashedRoll(msg.sender, faceValue.length, secret);
        for(uint8 i=0; i<faceValue.length; i++){
           emit SendNonHashedRoll(msg.sender, faceValue[i], faceValue[i]);
        }

        require(players[msg.sender].inGame == true, "You are not part of the game");
        require(players[msg.sender].numDice == faceValue.length, "Please send all your dice values");
        bool validate = validateReveal(faceValue, secret, players[msg.sender].concealedRollFaces);
        require( validate == true, "Your reveal does not match hashed values sent");
        if (callCount == 0){
            for (uint8 i=1; i<7; i++){
                rollFaceValues[i] = 0;
            }
        }
       
        for(uint8 i=0; i<faceValue.length; i++){
            players[msg.sender].revealedRollFaces[i] = faceValue[i];
            rollFaceValues[faceValue[i]] += 1;
        }
        callCount +=1;
        if(callCount == numActivePlayers){
            applyGameRules();
            if (turnOfPlayer == 255){
                stage = Stages.endGame;
                turnOfPlayer = 0;
            }else{
                stage = Stages.receiveHashedRoll;
            }
            callCount = 0;
            revealUpdateReady = true;
        }

    }
    /// @notice front end app should call this to display players that are still in game
    /// @return returns list of player's ids(positions) that are still in game
    function getActivePlayerLIst() public view returns(uint8[] memory) {
        uint8 []  memory activePlayers = new uint8[](playerList.length);
        uint8 idx = 0;
        for(uint8 i=0; i<playerList.length; i++){
            if (playerList[i] != address(0)){
                activePlayers[idx] = i;
                idx += 1;

            }
             
        }
        return  activePlayers;
    }

    /// @notice front end app should call this to display player's dice values after challenge
    /// @param playerPos: id/pos sent as part of getActivePlayerLIst call should be used 
    /// @return returns list of face values of players dice.
    function getPlayerReveal(uint8 playerPos) public view returns(uint256 [] memory){
        require(playerPos < numPlayers, "Player does not exist");
        address player = playerList[playerPos];
        uint256 [] memory revealVal = new uint256[](players[player].prevNumDice);

        for (uint8 i=0; i<players[player].prevNumDice; i++ ){
            revealVal[i]= players[player].revealedRollFaces[i];
        }
        return revealVal;
    }

   
    /// @dev Function that hashes value and secret
    /// @param value the value of the bid to be hashed
    /// @param secret the key with which the value is hashed 
    function getHash(uint256 value, uint256 secret) pure internal returns(bytes32) {

       return keccak256(abi.encodePacked(value,secret));

    }

    /// @notice Bid losers call this function to get their money back
    function withDrawMoney() public atStage([Stages.endGame, Stages.endGame]){
        PlayerInfo storage info = players[msg.sender];
        require(info.exists == true, "Player does not exist in this game");
        uint256 returnamount = players[msg.sender].balance;
        info.balance = 0;
        info.exists = false;
        //Require withdrawal not be allowed if no money is owed
        require(returnamount != 0, "No Amount is due");
        msg.sender.transfer(returnamount);
        emit WithDrewMoney(msg.sender, returnamount);
        info.inGame = false;
        info.numDice = numSetDice;
        info.prevNumDice = numSetDice;
        playerList.pop(); // don't care by this time all except one are null address
        callCount +=1 ;
        if (callCount == numPlayers){
            deployer.transfer(address(this).balance);
            stage = Stages.initial;
            callCount = 0;
            revealUpdateReady = false;
            numActivePlayers = 0;
        }

    }

    /// @notice  Fallback function to receive any transfers
    receive() external payable { 
       
        
    }
    
}