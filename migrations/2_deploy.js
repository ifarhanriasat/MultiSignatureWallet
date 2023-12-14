const MultiSigWallet = artifacts.require("MultiSigWallet");

module.exports = function (deployer) {
  deployer.deploy(MultiSigWallet, ["0xCf78b9f845ac46D9F7F5Abe78832a61F6d58F19B", "0xE579b34adbE3cA63561CE75B69DB8ca1509B668b"], 2); // put your own addresses
};