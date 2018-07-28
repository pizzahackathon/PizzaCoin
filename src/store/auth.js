import firebase from '@/firebase'

const state = {
  user: {},
  isLogginIn: false
}

const mutations = {
  setUser (state, user) {
    if (user) {
      state.user = user
      state.isLogginIn = true
    } else {
      state.user = {}
      state.isLogginIn = false
    }
  }
}

const actions = {
  async login () {
    const provider = new firebase.auth.GoogleAuthProvider()
    await firebase.auth().signInWithPopup(provider)
  },
  async logout () {
    await firebase.auth().signOut()
  }
}

export default {
  namespaced: true,
  state,
  actions,
  mutations
}
