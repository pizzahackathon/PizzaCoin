<template>
  <div>Chart
      <charts :chart-data="dataCollection" :options="chartOptions"></charts>
      <div v-if="btcPrice">
          BTC
          <b-table :data="btcLists" :columns="column"></b-table>
      </div>
      <hr/>
      <div v-if="ethPrice">
          ETH
          <b-table :data="ethLists" :columns="column"></b-table>
      </div>
  </div>
</template>

<script>
import Charts from './Charts.js'
import axios from 'axios'
import btcData from './datas/btc'
import _ from 'lodash'
// import moment from 'moment'

export default {
  name: 'ChartComponent',
  components: { Charts },
  data () {
    return {
      btcPrice: null,
      ethPrice: null,
      btcLists: [],
      ethLists: [],
      labelDate: [],
      column: [
        // {
        //   field: 'symbol',
        //   label: 'Name'
        // },
        {
          field: 'price',
          label: 'Price'
        }
      ],
      chartOptions: {
        scales: {
          yAxes: [{
            ticks: {
              beginAtZero: true
            },
            gridLines: {
              display: true
            }
          }],
          xAxes: [ {
            gridLines: {
              display: false
            }
          }]
        },
        legend: {
          display: true
        },
        responsive: true,
        maintainAspectRatio: false
      },
      dataCollection: {}
    }
  },
  async mounted () {
    this.preapreLabelDate()
    const instance = axios.create({
      baseURL: 'https://api.coinmarketcap.com/v2/ticker/',
      headers: {
        'Content-Type': 'application/json'
      }
    })
    this.fillData()
    for (let i = 0; i <= 10; i++) {
      this.loadData(instance)
      await this.sleep(10)
      // console.log('i: ', i)
    }
  },
  methods: {
    async btcApi (instance) {
      const response = await instance.get('1/')
      this.btcPrice = response.data.data
      // console.log(this.btcPrice);
      const params = {
        // symbol: "",
        price: 0.0
      }
      // params.symbol = this.btcPrice.symbol;
      params.price = this.btcPrice.quotes.USD.price
      this.btcLists.push(params)
    },
    async ethApi (instance) {
      const response = await instance.get('1027/')
      this.ethPrice = response.data.data
      const params = {
        // symbol: "",
        price: 0.0
      }
      // params.symbol = this.ethPrice.symbol;
      params.price = this.ethPrice.quotes.USD.price
      this.ethLists.push(params)
    },
    async preapreLabelDate () {
      _.each(btcData, data => {
        // console.log(data.date)
        this.labelDate.push(data.date)
      })
    },
    sleep (time) {
      return new Promise(resolve => setTimeout(resolve, time * 1000))
    },
    loadData (instance) {
      this.btcApi(instance)
      this.ethApi(instance)
    },
    fillData () {
      this.dataCollection = {
        labels: this.labelDate,
        datasets: [
          {
            label: 'BTC',
            backgroundColor: '#f87979',
            data: [this.btcLists]
          },
          {
            label: 'ETH',
            backgroundColor: '#808080',
            data: [this.ethLists]
          }
        ]
      }
    }
  }
}
</script>
