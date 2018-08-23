// import API from '@/lib/API'

const state = {
  teams: [],
  teamCount: 0
}

const actions = {
  getTeamsProfile (context, teams) {
    console.log('action --> getTeamsProfile')
    context.commit('getTeamsProfile', teams)
  },
  creatTeam (context, teamname) {
    context.commit('creatTeam', teamname)
  },
  addMember (context, memberName) {
    context.commit('addMember', memberName)
  },
  removePlayer (context, player) {
    console.log(`removePlayer --> ${player.address}`)
    context.commit('removePlayer', player)
  },
  voteTeam (context, teamname) {
    console.log('voteTeam --> ' + teamname)
  },
  getTeamCount (context, teamCount) {
    context.commit('setTeamCount', teamCount)
  }
}

// ///////////////// //
// ---- MUTATION ----  //
// ///////////////// //

const mutations = {
  getTeamsProfile (state, teams) {
    /* eslint-disable */
    console.log('mutations --> getTeamsProfile' + teams)
        state.teams = teams;
        /* eslint-enable */
  },
  voteTeam (state, teamname) {

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
  removePlayer (state, team) {
    console.log(team.address)
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
  },
  setTeamCount (state, teamCount) {
    state.teamCount = teamCount
  }
}

export default {
  namespaced: true,
  state,
  actions,
  mutations
}
