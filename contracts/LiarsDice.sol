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
        //  bytes32 [numSetDice] concealedRollFaces;
        //  uint8 [numSetDice] revealedRollFaces;
    }

    address deployer = msg.sender;
    bool public revealUpdateReady = false;
    uint8 numPlayers =2;
    uint8 public numActivePlayers;
    uint8 public numRound=0;
    uint8 turnOfPlayer;
    uint256 public gameCost;
    uint8 callCount=0;
    uint8 public winnerPlayerPos;
    bidInfo currentBid;

    /// @dev players list player at pos 0 will strat the first bid 
    address [] playerList;

    /// @dev Info associated with players for all players 
    mapping(address => PlayerInfo) players;
    Stages public stage;
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

   
    /// @notice Constructor initialize default values
    // constructor ()   {
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


    function balanceof() external view returns(uint){
        
        return address(this).balance;
    }

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

     /// @dev Function to update turn of the player to do bid/challenge
    function updateTurn()  internal returns(uint8) {
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
     /// @dev Function to check if revealed values matches with hashed values sent before
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

      /// @dev Function to check if bid came as per current rules i.e increase face value or increase number of dices 
    ///  with that value
    function validateAndSaveBid(uint256 faceValue, uint8 numDice)  internal returns(bool) {
        bool validBid = false;
        if (currentBid.faceValue < faceValue){
           validBid = true;
        }
        if (currentBid.numDice < numDice){
           validBid = true;
        }
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
         numBidFaceFaluesInRoll += rollFaceValues[1]; // one is wildcard and count towards current bid face value
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
            players[looser].exists = false;
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
        // require(players[msg.sender].exists == true, "Already joined the game");
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

      /// @notice Players join by calling joinGame by sending the gameCost money in msg.value
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
        }

    }

      /// @notice Players join by calling joinGame by sending the gameCost money in msg.value
    function sendBid(uint8 faceValue, uint8 numDice) public  atStage([Stages.bid, Stages.bid_challenge]) returns(bool) {

        require(players[msg.sender].inGame == true, "You are not part of the game");
        require(playerList[turnOfPlayer] == msg.sender, "Not your turn to bid");
        bool result = validateAndSaveBid(faceValue, numDice);
        if (result == true) {
            currentBid.playerPos = turnOfPlayer;
            stage = Stages.bid_challenge;
            updateTurn();
        }
        // return result;
        return true;


    }

    function sendChallenge() public  atStage([Stages.bid_challenge, Stages.bid_challenge]) {

        require(players[msg.sender].inGame == true, "You are not part of the game");
        require(playerList[turnOfPlayer] == msg.sender, "Not your turn");
        stage = Stages.challenge;
    }

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