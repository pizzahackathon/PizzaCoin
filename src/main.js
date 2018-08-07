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
  console.log(`ddd >> ${isStaff}`)
  if (isStaff) {
    account = pizzaCoin.account
    store.dispatch('auth/isStaffLogin', account)
  }
}, 3000)

console.log('service >> ' + pizzaCoin.account)

Vue.use(Buefy)

Vue.config.productionTip = false

new Vue({
  store,
  router,
  render: h => h(App)
}).$mount('#app')
