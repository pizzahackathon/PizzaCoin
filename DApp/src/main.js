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
let intervalTime = 1000

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
  console.log(`isPlayer >> ${isPlayer}`)

  if (isStaff || isPlayer) {
    isStaff ? store.dispatch('auth/isStaffLogin', account) : store.dispatch('auth/isPlayerLogin', account)
    try {
      let name = isStaff ? await pizzaCoin.getStaffName(account) : await pizzaCoin.getPlayerName(account)
      const data = {
        role: isStaff ? 'Staff' : 'Player',
        name: name
      }
      store.dispatch('auth/playerInfo', data)
    } catch (error) {
      console.error(error)
    }
  }
  console.log('check tokenBalance --> ' + typeof parseInt(tokenBalance))
  let showToken = {
    isPlayer: isPlayer,
    tokenBalance: tokenBalance
  }
  store.dispatch('staff/getContractState', state)
  if (state === 'Voting') {
    intervalTime = 100
    // console.log('inteval' + intervalTime)
  }
  if (state === 'Voting Finished') {
    intervalTime = 100000
  }
  store.dispatch('auth/getTokenBalance', showToken)
  store.dispatch('team/getTeamCount', await pizzaCoin.getTeamCount())
  console.log('inteval' + intervalTime)
}, intervalTime)

Vue.use(Buefy)

Vue.config.productionTip = false

new Vue({
  store,
  router,
  render: h => h(App)
}).$mount('#app')
