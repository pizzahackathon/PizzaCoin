import Vue from 'vue'
import Router from 'vue-router'
import Home from './views/Home.vue'
// import Web3Example from './views/Web3Example'

Vue.use(Router)

export default new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home
    }
    // {
    //   path: '/web3Example',
    //   name: 'web3Example',
    //   component: Web3Example
    // }
  ]
})
