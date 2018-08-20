import Vue from 'vue'
import Router from 'vue-router'
import Home from './views/Home.vue'

import LeaderBoard from './components/LeaderBoard.vue'
// import Web3Example from './views/Web3Example'

Vue.use(Router)

export default new Router({
  // mode: 'history',
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home
    },
    {
      path: '/leader-board',
      name: 'leader-board',
      component: LeaderBoard
    },
    {
      path: '/livefeed',
      beforeEnter () {
        window.open('https://pizzahackathon.github.io/livefeed/', '_blank')
      }
    },
    {
      path: '/github',
      beforeEnter () {
        window.open('https://github.com/pizzahackathon/', '_blank')
      }
    }
  ]
})
