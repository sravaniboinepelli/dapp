const LiarsDice = artifacts.require("LiarsDice");

module.exports = function (deployer) {
    deployer.deploy(LiarsDice);
};