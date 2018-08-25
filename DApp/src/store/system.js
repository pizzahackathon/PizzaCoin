const state = {
  network: 'kovan',
  etherscanPrefix: 'https://kovan.etherscan.io',
  ethereumNode: 'wss://kovan.infura.io/ws', // Only websocker endpoint
  pizzaCoinAddr: '0xed38bf5e334077bad86ba5d503fcb38dd30006d3',
  pizzaCoinStaffAddr: '0x615ac1EAB45C4987e7A78DD19c18dAf598Ec4B88',
  pizzaCoinPlayerAddr: '0x798Af328AF5D909C1dFed610EAc605a15d18Ea34',
  pizzaCoinTeamAddr: '0xe6fd15D39A12e3BAAEf700a728C227ED37C8a618'
}

export default {
  namespaced: true,
  state
}
