const state = {
  network: 'kovan',
  etherscanPrefix: 'https://kovan.etherscan.io',
  ethereumNode: 'wss://kovan.infura.io/ws', // Only websocker endpoint
  pizzaCoinAddr: '0x76030b8f0e6e938afabe7662ec248f2b7815e6bb',
  pizzaCoinStaffAddr: '0xEa1E67465b688Ea1b30856F55AcD77af43376d01',
  pizzaCoinPlayerAddr: '0x785A811Ad43c733B0FdDd8113E8478bc2AEd02e0',
  pizzaCoinTeamAddr: '0x216C611001b2e8B6ff2cf51C5e9EB39ABE558E35'
}

export default {
  namespaced: true,
  state
}
