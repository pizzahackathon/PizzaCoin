<template>
  <div class="is-fluid">
    <div class="box">
      <h3>BTC Price</h3>
      <canvas id="btc-chart"></canvas>
    </div>
    <div class="box">
      <h3>ETH Price</h3>
      <canvas id="eth-chart"></canvas>
    </div>
  </div>
</template>

<script>
import Chart from 'chart.js'
import axios from 'axios'
import config from '@/config.js'
import moment from 'moment'

export default {
  name: 'ChartComponent',
  data () {
    return {
      samples: 0,
      speed: 0,
      timeout: 0,
      values: [],
      charts: [],
      value: 0,
      scale: 1,
      btcValues: [],
      ethValues: [],
      instance: null
    }
  },
  async mounted () {
    this.instance = axios.create({
      baseURL: config.chart.endPoint,
      headers: {
        'Content-Type': 'application/json'
      }
    })
    this.samples = 20
    this.speed = 250
    this.timeout = this.samples * this.speed
    this.addEmptyValues(this.btcValues, this.samples)
    this.addEmptyValues(this.ethValues, this.samples)
    this.initialize()
    if (config.isProd) {
      this.runChartPriceProd()
    } else {
      this.runChartPriceDev()
    }
  },
  methods: {
    async runChartPriceDev () {
      for (let i = 0; i < 100; i++) {
        this.advance()
        await this.sleep(10)
      }
    },
    async runChartPriceProd () {
      for (;;) {
        this.advance()
        await this.sleep(10)
      }
    },
    initialize () {
      this.charts.push(new Chart(document.getElementById('btc-chart'), {
        type: 'line',
        data: {
          datasets: [{
            data: this.btcValues,
            backgroundColor: 'rgba(255, 99, 132, 0.1)',
            borderColor: 'rgb(255, 99, 132)',
            borderWidth: 2,
            lineTension: 0.25,
            pointRadius: 0
          }]
        },
        options: {
          responsive: true,
          animation: {
            duration: this.speed * 1.5,
            easing: 'linear'
          },
          legend: false,
          scales: {
            xAxes: [{
              type: 'time',
              display: true
            }],
            yAxes: [{
              ticks: {
                max: config.chart.btcMax,
                min: config.chart.btcMin
              }
            }]
          }
        }
      }), new Chart(document.getElementById('eth-chart'), {
        type: 'line',
        data: {
          datasets: [{
            data: this.ethValues,
            backgroundColor: 'rgba(0, 71, 187, 0.1)',
            borderColor: 'rgb(0, 71, 187)',
            borderWidth: 2
          }]
        },
        options: {
          responsive: true,
          animation: {
            duration: this.speed * 1.5,
            easing: 'linear'
          },
          legend: false,
          scales: {
            xAxes: [{
              type: 'time',
              display: true
            }],
            yAxes: [{
              ticks: {
                max: config.chart.ethMax,
                min: config.chart.ethMin
              }
            }]
          }
        }
      }))
    },
    addEmptyValues (arr, n) {
      for (var i = 0; i < n; i++) {
        arr.push({
          x: moment().subtract((n - i) * this.speed, 'milliseconds').toDate(),
          y: null
        })
      }
    },
    updateCharts () {
      this.charts.forEach(
        (chart) => {
          chart.update()
        }
      )
    },
    progressBTCPrice () {
      this.loadData('1/').then(
        (price) => {
          this.btcValues.push({
            x: new Date(),
            y: price
          })
          this.btcValues.shift()
        }
      )
    },
    progressETHPrice () {
      this.loadData('1027/').then(
        (price) => {
          this.ethValues.push({
            x: new Date(),
            y: price
          })
          this.ethValues.shift()
        }
      )
    },
    advance () {
      if (this.values[0] !== null && this.scale < 4) {
        // rescale();
        this.updateCharts()
      }
      this.progressBTCPrice()
      this.progressETHPrice()
      this.updateCharts()
    },
    sleep (time) {
      return new Promise(resolve => setTimeout(resolve, time * 1000))
    },
    async loadData (endpoint) {
      const response = await this.instance.get(endpoint)
      return response.data.data.quotes.USD.price
    }
  }
}
</script>
