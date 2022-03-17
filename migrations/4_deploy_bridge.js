const TuniverBridge = artifacts.require("TuniverBridge");

module.exports = function (deployer) {
  deployer.deploy(TuniverBridge, '0xb30B31fa30b11E188177906b79A6a30aC6a38cD3', '0x2423e107D67DA0aCDB160546A0AE7cd7833affB3', 0);
};
