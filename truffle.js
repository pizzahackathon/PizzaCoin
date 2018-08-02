/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a 
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() { 
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>') 
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */

// See <http://truffleframework.com/docs/advanced/configuration>
// to customize your Truffle configuration!

module.exports = {
  networks: {
    dev_ganache: {
      host: 'localhost',
      port: 7545,
      network_id: '*' // Match any network id
      //,gas: 8000000,
      //gasPrice: 10000000000
    },
    dev_rinkeby: {
      host: 'localhost',
      port: 8545,
      network_id: '4',
      from: '0x4B8Ad23e5923c7F479F35615a05e5868325aA85B',
      gas: 7000000,   // 7500000
      gasPrice: 10000000000
    }
  }
};
