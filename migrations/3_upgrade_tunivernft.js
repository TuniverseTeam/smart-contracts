const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const TuniverNFT = artifacts.require('TuniverNFT');
// const TuniverNFTV3 = artifacts.require('TuniverNFTV3');

module.exports = async function (deployer) {
  const existing = await TuniverNFT.deployed();
  console.log(existing.address)
  const instance = await upgradeProxy('0x2423e107D67DA0aCDB160546A0AE7cd7833affB3', TuniverNFT, { deployer });
  // console.log("Prev", existing.address);
  // console.log("Upgraded", instance.address);
};