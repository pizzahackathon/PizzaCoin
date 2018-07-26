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
      // console.log(state.proposals.indexOf(members.groupId))
      console.log(members.groupId)
      // const score = state.proposals.filter(proposal => proposal.groupId === 'pzc1')
      state.proposals.map((proposal, index) => {
        if (proposal.groupId === members.groupId) {
          console.log(state.proposals[index].score++)
        }
      })

      // console.log(state.proposals.indexOf(score))

      // state.members.score++
    },
    removeMember (state, member) {
      console.log(member.token)
      state.proposals.map((proposal, index) => {
        console.log((proposal.detail).indexOf(member.token))
        proposal.detail.map((mem, idx) => {
          if (proposal.detail[idx].token === member.token) {
            // state.proposals.detail[idx].splice(idx, 1)
            // console.log(state.proposals[index].detail[idx])
            console.log(state.proposals[index].detail.splice(idx, 1))
          }
        })
      })
    }
  }
})
