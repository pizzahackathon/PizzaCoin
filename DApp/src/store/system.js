const state = {
  network: 'kovan',
  etherscanPrefix: 'https://kovan.etherscan.io',
  ethereumNode: 'wss://kovan.infura.io/ws', // Only websocker endpoint
  pizzaCoinAddr: '0xd5104240e1a449c2a7f22db74adc5d633a26748b',
  pizzaCoinStaffAddr: '0x2e75cfb85acd1667d60e2325396CF5953cF205D7',
  pizzaCoinPlayerAddr: '0x6658EBa89b9016248Ac70EFb959C7C96c5ee7e3A',
  pizzaCoinTeamAddr: '0x5C4f4A508293a7EA5c0a8Ae7Dfaac3c60E4b2d09'
}

export default {
  namespaced: true,
  state
}
