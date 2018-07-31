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
})
