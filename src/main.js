import Vue from 'vue'
import App from './App.vue'
import store from '@/store'
import router from './router'
import 'buefy/lib/buefy.css'
import Buefy from 'buefy'
import Pizzacoin from '@/PizzaCoin'

const pizzaCoin = new Pizzacoin()
Vue.prototype.$pizzaCoin = pizzaCoin
Vue.prototype.$store = store

setInterval(async function () {
  let account = pizzaCoin.account
  console.log('service >> ' + account)
  let isStaff = await pizzaCoin.isStaff(account)
  let tokenBalance = await pizzaCoin.getTokenBalance('0x006dA2313d578dac3D1eCE86c17Fe914a14D18C5')
  // let tokenBalance = await pizzaCoin.getTokenBalance(account)
  console.log(`ddd >> ${isStaff}`)
  if (isStaff) {
    account = pizzaCoin.account
    store.dispatch('auth/isStaffLogin', account)
  }
  console.log('check tokenBalance --> ' + typeof parseInt(tokenBalance))
  store.dispatch('auth/getTokenBalance', tokenBalance)
}, 3000)

// store.dispatch('team/getTeamsProfile')

console.log('service >> ' + pizzaCoin.account)

Vue.use(Buefy)

Vue.config.productionTip = false

new Vue({
  store,
  router,
  render: h => h(App)
}).$mount('#app')
