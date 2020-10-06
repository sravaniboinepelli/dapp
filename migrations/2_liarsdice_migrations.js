const LiarsDice = artifacts.require("LiarsDice");
const argv = require('minimist')(process.argv.slice(3));

//If you arent running blockchain on ganache, comment this out
var noofPlayers = argv['noOfPlayers'];
var cost = argv['gameCost'];

//Use either the declaration below, or change the values inside the contract itself if not using ganache
//var minPrice = argv['minPrice'];
//var noOfBids = argv['noOfBids'];
console.log(argv);
console.log(noofPlayers);
console.log(cost);

module.exports = (deployer,network,accounts) => {
  deployer.deploy(LiarsDice, noofPlayers, cost);
};


