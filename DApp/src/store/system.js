const state = {
  network: 'kovan',
  etherscanPrefix: 'https://kovan.etherscan.io',
  ethereumNode: 'wss://kovan.infura.io/ws', // Only websocker endpoint
  pizzaCoinAddr: '0xe960868fa9e521f853ade9d5b40088b6387592f0',
  pizzaCoinStaffAddr: '0x0C7FfBfAB626dDB6278CC1a20BA471981d1C8048',
  pizzaCoinPlayerAddr: '0xfD4B7211Abb8b41bf45805A8F177FF4f22F52E36',
  pizzaCoinTeamAddr: '0x156e3718c6F8EF104141f147FDd79775B7085783'
}

export default {
  namespaced: true,
  state
}
