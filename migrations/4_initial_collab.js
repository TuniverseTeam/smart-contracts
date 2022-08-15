const TuniverCollaborator = artifacts.require("TuniverCollaborator");

module.exports = function (deployer) {
  deployer.deploy(TuniverCollaborator);
};
