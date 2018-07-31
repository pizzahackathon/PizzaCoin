import Vue from 'vue'
import App from './App.vue'

import Buefy from 'buefy'
import 'buefy/lib/buefy.css'

import VueCharts from 'vue-chartjs'

Vue.config.productionTip = false
Vue.use(Buefy)
Vue.use(VueCharts)

new Vue({
  render: h => h(App)
}).$mount('#app')
