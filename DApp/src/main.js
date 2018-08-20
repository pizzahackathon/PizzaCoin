import Vue from 'vue'
import App from './App.vue'
import store from '@/store'
import router from './router'
import 'buefy/lib/buefy.css'
import Buefy from 'buefy'
import Pizzacoin from '@/PizzaCoin'

//
// ─── INITIAL PIZZA COIN ─────────────────────────────────────────────────────────
//
const pizzaCoin = new Pizzacoin(
  store.state.system.network,
  store.state.system.ethereumNode,
  store.state.system.pizzaCoinAddr,
  store.state.system.pizzaCoinStaffAddr,
  store.state.system.pizzaCoinTeamAddr,
  store.state.system.pizzaCoinPlayerAddr)
Vue.prototype.$pizzaCoin = pizzaCoin

Vue.prototype.$store = store

setInterval(async function () {
  let account = await pizzaCoin.account
  console.log('service >> ' + account)
  let isStaff = await pizzaCoin.isStaff(account)
  let isPlayer = await pizzaCoin.isPlayer(account)
  // let userName = await pizzaCoin.getPlayerName(account)
  // let tokenBalance = await pizzaCoin.getTokenBalance('0x006dA2313d578dac3D1eCE86c17Fe914a14D18C5')
  let tokenBalance = await pizzaCoin.getTokenBalance(account)
  let state = await pizzaCoin.getContractState(account)
  console.log('check state --> ' + state)
  console.log(`isStaff >> ${isStaff}`)
  if (isStaff) {
    store.dispatch('auth/isStaffLogin', account)
  } else if (isPlayer) {
    store.dispatch('auth/isPlayerLogin', account)
  }
  console.log('check tokenBalance --> ' + typeof parseInt(tokenBalance))
  let showToken = {
    isPlayer: isPlayer,
    tokenBalance: tokenBalance
  }
  store.dispatch('staff/getContractState', state)
  store.dispatch('auth/getTokenBalance', showToken)
}, 3000)

// store.dispatch('team/getTeamsProfile')

Vue.use(Buefy)

Vue.config.productionTip = false

new Vue({
  store,
  router,
  render: h => h(App)
}).$mount('#app')
