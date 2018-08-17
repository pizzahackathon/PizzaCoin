
const state = {
  user: {},
  isLoggedIn: false,
  isLoading: 0,
  userAddress: '',
  userName: '',
  tokenBalance: 0,
  role: ''
}

const mutations = {
  setLoading (state, value) {
    state.isLoading += value
  },
  isStaffLogin (state, payload) {
    console.log(` payload >> ${payload}`)
    state.isLoggedIn = true
    state.role = 'Staff'
  },
  isPlayerLogin (state, payload) {
    console.log(` payload >> ${payload}`)
    state.isLoggedIn = false
    state.role = 'Player'
  },
  getTokenBalance (state, {isPlayer, tokenBalance}) {
    console.log(` isPlayer >> ${isPlayer}`)
    if (isPlayer || state.isLoggedIn) {
      state.tokenBalance = tokenBalance
    } else {
      state.tokenBalance = 0
    }
  }
}

const actions = {
  async isStaffLogin ({commit}, payload) {
    console.log(`actions isStaffLogin >> ${payload}`)
    commit('isStaffLogin', payload)
  },
  async isPlayerLogin ({commit}, payload) {
    console.log(`actions isPlayerLogin >> ${payload}`)
    commit('isPlayerLogin', payload)
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
