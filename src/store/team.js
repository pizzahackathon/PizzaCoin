import API from '@/lib/API'
const uuid = require('uuid')

console.log(uuid)

// console.log(API.getProposal())

const state = {
  members: []
}

const getters = {
  members (state) {
    return state.members
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

        state.members = proposals;
        /* eslint-enable */
  },
  addScore (state, team) {
    // console.log(state.proposals.indexOf(members.groupId))
    console.log(team.groupId)
    // const score = state.proposals.filter(proposal => proposal.groupId === 'pzc1')
    state.members.map((member, index) => {
      if (member.groupId === team.groupId) {
        console.log(state.members[index].score++)
      }
    })

    // console.log(state.proposals.indexOf(score))

    // state.members.score++
  },
  removeMember (state, team) {
    console.log(team.address + 'sss')
    state.members.map((member, index) => {
      console.log((member.detail).indexOf(team.address))
      member.detail.map((mem, idx) => {
        if (member.detail[idx].address === team.address) {
          // state.proposals.detail[idx].splice(idx, 1)
          // console.log(state.proposals[index].detail[idx])
          console.log(state.members[index].detail.splice(idx, 1))
        }
      })
    })
  },
  creatTeam (state, teamname) {
    console.log(teamname)
    console.log(state.members.push(
      {
        'groupId': teamname,
        'groupName': teamname,
        'score': 3,
        'detail': [
        ]
      }
    ))
  },
  addMember (state, {memberName, team}) {
    console.log(team.groupName)
    state.members.map((member, index) => {
      if (member.groupId === team.groupId) {
        console.log(state.members[index].detail.push({
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
