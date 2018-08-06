import API from '@/lib/API'

const state = {
  teams: []
}

const getters = {
  teams (state) {
    return state.teams
  }
}

const actions = {
  async getProposal (context) {
    console.log(context)
    const proposals = await API.getProposal()
    console.log(proposals)
    console.log('test')

    context.commit('setProposals', proposals)
  },
  creatTeam (context, teamname) {
    context.commit('creatTeam', teamname)
  },
  addMember (context, memberName) {
    context.commit('addMember', memberName)
  }
}
const mutations = {
  setProposals (state, proposals) {
    /* eslint-disable */

        state.teams = proposals;
        /* eslint-enable */
  },
  addScore (state, team) {
    // console.log(state.proposals.indexOf(members.groupId))
    console.log(team.groupId)
    // const score = state.proposals.filter(proposal => proposal.groupId === 'pzc1')
    state.teams.map((member, index) => {
      if (member.groupId === team.groupId) {
        console.log(state.teams[index].score++)
      }
    })

    // console.log(state.proposals.indexOf(score))

    // state.members.score++
  },
  removeMember (state, team) {
    console.log(team.address + 'sss')
    state.teams.map((member, index) => {
      console.log((member.detail).indexOf(team.address))
      member.detail.map((mem, idx) => {
        if (member.detail[idx].address === team.address) {
          // state.proposals.detail[idx].splice(idx, 1)
          // console.log(state.proposals[index].detail[idx])
          console.log(state.teams[index].detail.splice(idx, 1))
        }
      })
    })
  },
  creatTeam (state, teamname) {
    console.log(teamname)
    console.log(state.teams.push(
      {
        'groupId': teamname,
        'groupName': teamname,
        'score': 3,
        'detail': [
        ]
      }
    ))
  },
  addMember (state, {memberName, teamMebers}) {
    console.log(teamMebers.groupName)
    state.teams.map((member, index) => {
      if (member.groupId === teamMebers.groupId) {
        console.log(state.teams[index].detail.push({
          name: memberName,
          address: memberName
        }))
      }
    })
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
