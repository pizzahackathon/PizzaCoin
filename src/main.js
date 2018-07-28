import Vue from 'vue'
import App from './App.vue'
import store from './store/'
import router from './router'
import 'buefy/lib/buefy.css'
import Buefy from 'buefy'
/* eslint-disable */
import firebase from './firebase'
import auth from './auth'
/* eslint-disable */

Vue.use(Buefy)

Vue.config.productionTip = false

new Vue({
  store,
  router,
  render: h => h(App)
}).$mount('#app')
