// See <http://truffleframework.com/docs/advanced/configuration>
// to customize your Truffle configuration!

var HDWalletProvider = require('truffle-hdwallet-provider');
var mnemonic = require('./mnemonic.secret');
var infuraApi = require('./infura-api.secret');

module.exports = {
  networks: {
    mainnet: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/' + infuraApi);
      },
      network_id: '1'
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/' + infuraApi);
      },
      network_id: '3'
    },
    rinkeby: {
      provider: function() {
        //return new HDWalletProvider(mnemonic, 'http://localhost:8545');
        return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/' + infuraApi);
      },
      network_id: '4'
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://kovan.infura.io/' + infuraApi);
      },
      network_id: '42'
    },
    rinkeby_localsync: {
      host: 'localhost',
      port: 8545,
      network_id: '4',
      from: '0x4B8Ad23e5923c7F479F35615a05e5868325aA85B'
    },
    ganache: {
      host: 'localhost',
      port: 7545,
      network_id: '*' // Match any network id
    } 
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};