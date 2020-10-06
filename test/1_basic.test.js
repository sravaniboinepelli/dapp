const { SSL_OP_EPHEMERAL_RSA } = require("constants");
const sleep = (milliseconds) =>
{
    return new Promise(resolve => setTimeout(resolve, milliseconds))
}
var LiarsDice = artifacts.require("./LiarsDice.sol");
var accounts;

web3.eth.getAccounts().then((acc) =>
{
    accounts = acc;
});

contract("LiarsDice", (accounts) =>
{
    before(async () =>
    {
        inst1 = await LiarsDice.deployed();
    })


    it("test1", async () =>
    {
        var i;
        var numDice = 5;
        var faceValue1 = [];
        var hasFaceValue1 = [];
        var hasFaceValue2 = [];
        var faceValue2 = [];
        var secret = 10;
        var player1 = accounts[2];
        var player2 = accounts[1];
        var timeout = 1000
        for (let i = 0; i < 5; i++) 
        {
            
            val1 = Math.floor(Math.random() * (6 - 1 + 1) + 1);
            val2 = Math.floor(Math.random() * (6 - 1 + 1) + 1);
            faceValue1.push(val1);
            hx1 = web3.utils.soliditySha3(val1, secret);
            bt1 = web3.utils.hexToBytes(hx1);
            hasFaceValue1.push(bt1);
            faceValue2.push(val2);
            hx2 = web3.utils.soliditySha3(val2, secret)
            bt2 = web3.utils.hexToBytes(hx2)
            hasFaceValue2.push(bt2);
        }  
        console.log(faceValue1);
        console.log(faceValue2);

        inst1.joinGame({from:player1,value:0x40});
        inst1.joinGame({from:player2,value:0x40});
        await sleep(timeout);
         
        console.log(inst1.balanceof())
        console.log(inst1.stage())
        console.log("hash calls");
        console.log(hasFaceValue1);
        await sleep(timeout);
        inst1.recvHashedRoll(hasFaceValue1, {from:player1})
        inst1.recvHashedRoll(hasFaceValue2, {from:player2})
        await sleep(timeout);
        console.log("bid");

        inst1.sendBid(faceValue1[0], 2, {from:player1})
        await sleep(timeout);
        console.log("challenge");
        inst1.sendChallenge({from:player2})
        await sleep(timeout);
        console.log("reveal");
        inst1.sendNonHashedRoll(faceValue1, secret, {from:player1})
        inst1.sendNonHashedRoll(faceValue2, secret, {from:player2})
        console.log("update");
        await sleep(timeout);
        inst1.revealUpdateReady({from:player1})
        await sleep(timeout);
        console.log("activePlayers");

        inst1.numActivePlayers({from:player1})
        actPlayer = inst1.getActivePlayerLIst({from:player1})

        for (i=0; i< actPlayer.length; i++){
        inst1.getPlayerReveal(actPlayer[i], {from:player1})
        }
        console.log(inst1.stage());
        console.log(inst1.winnerPlayerPos());
        
    })
   
}); 
