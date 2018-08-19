// import API from '@/lib/API'

const state = {
  stateContract: ''
}

const actions = {
  getContractState (context, stateContract) {
    console.log('action --> getContractState')
    context.commit('getContractState', stateContract)
  }
}

// ///////////////// //
// ---- MUTATION ----  //
// ///////////////// //

const mutations = {
  getContractState (state, stateContract) {
    /* eslint-disable */
      console.log('mutations --> getContractState')
          state.stateContract = stateContract;
          /* eslint-enable */
  }
}

export default {
  namespaced: true,
  state,
  actions,
  mutations
}
