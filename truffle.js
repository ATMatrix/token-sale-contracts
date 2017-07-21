const HDWalletProvider = require('truffle-hdwallet-provider');
const mnemonic = 'ATMatrix Token';
module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    kovan: {
      network_id: 42,
      provider:  new HDWalletProvider(mnemonic, 'https://kovan.infura.io', 0),
      gas: 4.6e6,
      from: "0x34B0b1e9E42721E9E4a3D38A558EB0155a588340",
    }
  }
};
