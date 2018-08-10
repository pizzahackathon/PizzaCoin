
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
  getTokenBalance (state, {isPlayer, tokenBalance}) {
    console.log(` isPlayer >> ${isPlayer}`)
    if (isPlayer) {
      state.tokenBalance = tokenBalance
    } else {
      state.tokenBalance = 0
    }
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
  getTokenBalance ({commit}, payload) {
    console.log(` getTokenBalance >> ${payload}`)
    commit('getTokenBalance', payload)
  }
}

export default {
  namespaced: true,
  state,
  actions,
  mutations
}
