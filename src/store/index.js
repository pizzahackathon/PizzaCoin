import Vue from 'vue'
import Vuex from 'vuex'

// import API from '@/lib/API'
import auth from './auth'
import team from './team'

Vue.use(Vuex)

export default new Vuex.Store({
  modules: {
    auth,
    team
  },
  state: {
    // members: [],
    teamname: ''
  }
  // getters: {
  //   members (state) {
  //     return state.members
  //   }
  // },
  // actions: {
  //   async getProposal (context) {
  //     console.log(context)
  //     const proposals = await API.getProposal()
  //     console.log(proposals)
  //     context.commit('setProposals', proposals)
  //   }
  // },
  // mutations: {
  //   setProposals (state, proposals) {
  //     /* eslint-disable */
  //     state.members = proposals;
  //     /* eslint-enable */
  //   },
  //   addScore (state, team) {
  //     // console.log(state.proposals.indexOf(members.groupId))
  //     console.log(team.groupId)
  //     // const score = state.proposals.filter(proposal => proposal.groupId === 'pzc1')
  //     state.members.map((member, index) => {
  //       if (member.groupId === team.groupId) {
  //         console.log(state.members[index].score++)
  //       }
  //     })

  //     // console.log(state.proposals.indexOf(score))

  //     // state.members.score++
  //   },
  //   removeMember (state, team) {
  //     console.log(team.token)
  //     state.members.map((member, index) => {
  //       console.log((member.detail).indexOf(team.token))
  //       member.detail.map((mem, idx) => {
  //         if (member.detail[idx].token === team.token) {
  //           // state.proposals.detail[idx].splice(idx, 1)
  //           // console.log(state.proposals[index].detail[idx])
  //           console.log(state.members[index].detail.splice(idx, 1))
  //         }
  //       })
  //     })
  //   },
  //   onCreateTeam (state) {
  //     console.log(this.state.members.push(
  //       {
  //         'groupId': 'pzc4',
  //         'groupName': 'hackbaobao',
  //         'score': 3,
  //         'detail': [
  //         ]
  //       }
  //     ))
  //   }
  // }
})
