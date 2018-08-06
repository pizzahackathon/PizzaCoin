
const state = {
  user: {},
  isLoggedIn: false,
  isLoading: 0,
  userAddress: ''
}

const mutations = {
  setLoading (state, value) {
    state.isLoading += value
  },
  // setUser (state, user) {
  //   if (user) {
  //     // console.log(this.$pizzaCoin.isStaff('0xbcb64e193A59f5360EdfCedE6FdAc82A89bDF8fa'))
  //     state.user = user
  //     state.isLoggedIn = true
  //   } else {
  //     state.user = {}
  //     state.isLoggedIn = false
  //   }
  // },
  isStaffLogin (state, payload) {
    console.log(` payload >> ${payload}`)

    state.isLoggedIn = payload
  }
}

const actions = {
  async isStaffLogin ({commit}, payload) {
    console.log(`actions >> ${payload}`)
    commit('isStaffLogin', payload)
  },
  async setIsLoading ({ commit }, value) {
    commit('setLoading', value)
  }
}

export default {
  namespaced: true,
  state,
  actions,
  mutations
}
