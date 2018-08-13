import Vue from 'vue'
import App from './App.vue'
import moment from 'moment'

import Buefy from 'buefy'
import 'buefy/lib/buefy.css'

import VueCharts from 'vue-chartjs'
import VueYouTubeEmbed from 'vue-youtube-embed'

Vue.config.productionTip = false
Vue.use(Buefy)
Vue.use(VueCharts)
Vue.use(VueYouTubeEmbed)

Vue.filter('formatDate', (value) => {
  if (value) {
    return moment(String(value)).format('LLL')
  }
})

new Vue({
  render: h => h(App)
}).$mount('#app')
