import Vue from 'vue'
import Vuex from 'vuex'

// import API from '@/lib/API'
import auth from '@/store/auth'
import team from './team'
import staff from './staff'
import system from './system'

Vue.use(Vuex)

export default new Vuex.Store({
  modules: {
    auth,
    team,
    staff,
    system
  },
  state: {
    // members: [],
    teamname: ''
  }
})
