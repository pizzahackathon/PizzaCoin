const state = {
  network: 'ropsten',
  etherscanPrefix: 'https://ropsten.etherscan.io',
  ethereumNode: 'wss://ropsten.infura.io/_ws', // Only websocker endpoint
  pizzaCoinAddr: '0x2f1d21D4667BA3744bf031d6cd6Cef2109cCc090',
  pizzaCoinStaffAddr: '0x0E87749faD6fBAE09C3A01D4B0FF3b5128fD5675',
  pizzaCoinTeamAddr: '0xc336A6537b820bF530BfcdECF5Efb6c33bE49c77',
  pizzaCoinPlayerAddr: '0x12998F6E32D3f76D856c92eD88428E5A7630aC29'
}
// Rinkeby
// this.pizzaCoinAddr = '0x5aa5bf8f1a386f6f3cc564548890ee9a7382718d'
// this.pizzaCoinStaffAddr = '0xb25eE5C4d11F9D934f2642d30c99319708e615D4'
// this.pizzaCoinTeamAddr = '0x164d120357CAc5Cea08c201D719c7D48b2054b8e'
// this.pizzaCoinPlayerAddr = '0xD1571785b4309F55294EF7593276B7B5505F103A'

// Ropsten
// this.pizzaCoinAddr = '0x2f1d21D4667BA3744bf031d6cd6Cef2109cCc090'
// this.pizzaCoinStaffAddr = '0x0E87749faD6fBAE09C3A01D4B0FF3b5128fD5675'
// this.pizzaCoinTeamAddr = '0xc336A6537b820bF530BfcdECF5Efb6c33bE49c77'
// this.pizzaCoinPlayerAddr = '0x12998F6E32D3f76D856c92eD88428E5A7630aC29'

export default {
  namespaced: true,
  state
}
