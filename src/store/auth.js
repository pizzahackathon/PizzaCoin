
const state = {
  user: {},
  isLoggedIn: false,
  isLoading: 0,
  userAddress: '',
  tokenBalance: 0
}

const mutations = {
  setLoading (state, value) {
    state.isLoading += value
  },
  isStaffLogin (state, payload) {
    console.log(` payload >> ${payload}`)
    state.isLoggedIn = payload
  },
  getTokenBalance (state, tokenBalance) {
    console.log(` getTokenBalance >> ${typeof tokenBalance}`)
    state.tokenBalance = tokenBalance
  }
}

const actions = {
  async isStaffLogin ({commit}, payload) {
    console.log(`actions >> ${payload}`)
    commit('isStaffLogin', payload)
  },
  async setIsLoading ({ commit }, value) {
    commit('setLoading', value)
  },
  getTokenBalance ({commit}, tokenBalance) {
    console.log(` getTokenBalance >> ${tokenBalance}`)
    commit('getTokenBalance', tokenBalance)
  }
}

export default {
  namespaced: true,
  state,
  actions,
  mutations
}
