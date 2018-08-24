const state = {
  network: 'kovan',
  etherscanPrefix: 'https://kovan.etherscan.io',
  ethereumNode: 'wss://kovan.infura.io/ws', // Only websocker endpoint
  pizzaCoinAddr: '0x2ae53961e6cad27ed6ef71c4b1e6021786d7846b',
  pizzaCoinStaffAddr: '0x2F1f50dc6F3D9B77FFd5b6C7769c2C28423099f2',
  pizzaCoinPlayerAddr: '0x377474c7afD40Dd75f4a6952CCB3bA69EF165159',
  pizzaCoinTeamAddr: '0xb35F30854F7A4a4c5Dd61a7C410bAd2541ffaAE8'
}

export default {
  namespaced: true,
  state
}
