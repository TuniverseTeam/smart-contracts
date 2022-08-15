const TuniverBox = artifacts.require("TuniverBox");

module.exports = function (deployer) {
  deployer.deploy(TuniverBox, "Testing");
};
