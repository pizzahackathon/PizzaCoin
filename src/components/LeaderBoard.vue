/* eslint-disable */
<template>
  <div>Leader board
      <canvas id="leader-board-chart"></canvas>
  </div>
</template>
<script>
import Chart from 'chart.js'
import LeaderBoardData from './chartData.js'
import Web3 from 'web3'
import PizzaCoinAbi from '@/abi/PizzaCoinAbi.json'

export default {
  name: 'LeaderBoardComponent',
  data () {
    return {
      leaderBoardData: LeaderBoardData,
      pizzaCoin: null
    }
  },
  mounted () {
    this.createWeb3()
    this.createChart('leader-board-chart', this.leaderBoardData)
    this.subscribeEvent()
  },
  methods: {
    createWeb3 () {
      var web3 = new Web3(new Web3.providers.WebsocketProvider('wss://rinkeby.infura.io/_ws'))
      // var web3 = new Web3(new Web3.providers.WebsocketProvider('wss://rinkeby.infura.io/v3/4e81201d04f84222a663fa0efe57270e'))
      this.pizzaCoin = new web3.eth.Contract(
        PizzaCoinAbi,
        this.$pizzaCoin.pizzaCoinAddr
        // PizzaCoinJson.networks[4].address     // Rinkeby
      )
    },
    createChart (chartId, chartData) {
      const ctx = document.getElementById(chartId)
      this.leaderBoardChart = new Chart(ctx, {
        type: chartData.type,
        data: chartData.data,
        options: chartData.options
      })
    },
    subscribeEvent () {
      // Subscribe to 'TeamVoted' event (this requires a web3-websocket provider)
      // See: https://web3js.readthedocs.io/en/1.0/web3-eth-contract.html#contract-events
      let subscription = this.pizzaCoin.events.TeamVoted(null, (err, result) => {
        if (err) {
          throw new Error(err)
        }

        let teamName, totalVoted
        teamName = result.returnValues._teamName
        totalVoted = result.returnValues._totalVoted

        console.log('***** Event catched *****')
        console.log('teamName: ' + teamName)
        console.log('totalVoted: ' + totalVoted)
      })

      return subscription
    }
  }
}
</script>
