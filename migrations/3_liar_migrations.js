const Liars = artifacts.require("Liars");


module.exports = (deployer,network,accounts) => {
  deployer.deploy(Liars);
};


