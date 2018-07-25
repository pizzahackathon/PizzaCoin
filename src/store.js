import Vue from 'vue'
import Vuex from 'vuex'

import API from './lib/API'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    proposals: []
  },
  getters: {
    proposals (state) {
      return state.proposals
    }
  },
  actions: {
    async getProposal (context) {
      console.log(context)
      const proposals = await API.getProposal()
      console.log(proposals)
      context.commit('setProposals', proposals)
    }
  },
  mutations: {
    setProposals (state, proposals) {
      /* eslint-disable */
      state.proposals = proposals;
      /* eslint-enable */
    },
    addScore (state, members) {
      console.log(members)
      state.members.score++
    },
    removeMember (state, member) {
      console.log(state.proposals)
      const index = state.proposals.detail.indexOf(member)
      state.proposals.detail.splice(index, 1)
    }
  }
})
