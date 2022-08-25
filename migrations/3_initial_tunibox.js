const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const TuniverBox = artifacts.require("TuniverBox");
// Deploy new contract
module.exports = async function (deployer) {
  const instance = await deployProxy(TuniverBox, ['https://api.thewastedlands.io/api/hero/'], { initializer: 'initialize' });
  // deployer.deploy(WastedWhitelist, '0xd1a4A413C0f11904CE952C074F35d4D091D13497');
};