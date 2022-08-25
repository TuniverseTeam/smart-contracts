const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const TuniverBox = artifacts.require('TuniverBox');

module.exports = async function (deployer) {
  const instance = await upgradeProxy('0xfB9130e14325cBC95A896d34F8F09638384103D4', TuniverBox, { deployer });
};