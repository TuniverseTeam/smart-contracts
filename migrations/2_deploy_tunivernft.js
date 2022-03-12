const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const TuniverNFT = artifacts.require("TuniverNFT");
// Deploy new contract
module.exports = async function (deployer) {
  const instance = await deployProxy(TuniverNFT, ['https://test.thewastedlands.io/api/hero/'], { initializer: 'initialize' });
};