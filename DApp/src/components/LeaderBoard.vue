/* eslint-disable */
<template>
  <div>
      Leader board
      <canvas id="leader-board-chart"></canvas>
      Team count {{ teamCount }}
  </div>
</template>
<script>
import Chart from 'chart.js'
import Web3 from 'web3'
import PizzaCoinAbi from '@/abi/PizzaCoinAbi.json'
import { mapState } from 'vuex'
import _ from 'lodash'

export default {
  name: 'LeaderBoardComponent',
  computed: {
    ...mapState('team', ['teams', 'teamCount'])
  },
  data () {
    return {
      leaderBoardData: null,
      pizzaCoin: null,
      teamNames: [],
      teamScore: [],
      showTeamNameOnState: 'Voting Finished',
      currentState: ''
    }
  },
  async mounted () {
    this.createWeb3()
    this.subscribeEvent()
    await this.loadData()
    this.initChartInstance()
    this.initialLabels()
    this.createChart('leader-board-chart', this.leaderBoardData)
  },
  methods: {
    async loadData () {
      this.currentState = await this.$pizzaCoin.getContractState(this.$pizzaCoin.account)
      await this.$store.dispatch('team/getTeamsProfile', await this.$pizzaCoin.getTeamsProfile())
      _.forEach(this.teams, (team, idx) => {
        console.log('team: ', team)
        console.log('teamName: ', team.name)
        console.log('total vote: ', team.score)

        if (this.currentState === this.showTeamNameOnState) {
          this.teamNames.push(team.name)
        } else {
          this.teamNames.push('')
        }
        this.teamScore.push(team.score)
      })
    },
    initChartInstance (bgColor, borderColor) {
      this.leaderBoardData = {
        type: 'bar',
        data: {
          labels: this.teamNames,
          datasets: [
            { // one line graph
              label: 'Score voting',
              data: this.teamScore,
              backgroundColor: [
                'rgba(255, 0, 0, 0.5)',
                'rgba(85, 0, 255, 0.5)',
                'rgba(64, 255, 0, 0.5)',
                'rgba(236, 66, 249, 0.5)',
                'rgba(84, 23, 167, 0.5)',
                'rgba(206, 31, 147, 0.5)',
                'rgba(203, 133, 246, 0.5)',
                'rgba(166, 159, 22, 0.5)',
                'rgba(31, 215, 109, 0.5)',
                'rgba(107, 203, 204, 0.5)',
                'rgba(29, 61,1 45, 0.5)',
                'rgba(174, 99, 20 , 0.5)',
                'rgba(26, 123, 92 , 0.5)',
                'rgba(64, 97, 253, 0.5)',
                'rgba(35, 176, 25, 0.5)'
              ],
              borderColor: [
                'rgba(255, 0, 0)',
                'rgba(85, 0, 255)',
                'rgba(64, 255, 0)',
                'rgba(236, 66, 249)',
                'rgba(84, 23, 167)',
                'rgba(206, 31, 147)',
                'rgba(203, 133, 246)',
                'rgba(166, 159, 22)',
                'rgba(31, 215, 109)',
                'rgba(107, 203, 204)',
                'rgba(29, 61,1 45)',
                'rgba(174, 99, 20 )',
                'rgba(26, 123, 92 )',
                'rgba(64, 97, 253)',
                'rgba(35, 176, 25)'
              ],
              borderWidth: 3
            }
          ]
        },
        options: {
          responsive: true,
          lineTension: 1,
          scales: {
            yAxes: [{
              ticks: {
                beginAtZero: true,
                padding: 25
              }
            }]
          }
        }
      }
    },
    initialLabels () {
      const self = this
      // Define a plugin to provide data labels
      Chart.plugins.register({
        afterDatasetsDraw: function (chart) {
          var ctx = chart.ctx
          chart.data.datasets.forEach(function (dataset, i) {
            var meta = chart.getDatasetMeta(i)
            if (!meta.hidden) {
              meta.data.forEach(function (element, index) {
                // Draw the text in black, with the specified font
                ctx.fillStyle = 'rgb(0, 0, 0)'
                var fontSize = 25
                var fontStyle = 'normal'
                var fontFamily = 'Helvetica Neue'
                ctx.font = Chart.helpers.fontString(fontSize, fontStyle, fontFamily)
                // Just naively convert to string for now
                var dataString = dataset.data[index].toString()
                if (parseInt(dataString) !== 0) {
                  // Make sure alignment settings are correct
                  ctx.textAlign = 'center'
                  ctx.textBaseline = 'middle'
                  var padding = 5
                  var position = element.tooltipPosition()
                  ctx.fillText(dataString, position.x, position.y - (fontSize / 2) - padding)

                  if (self.currentState === self.showTeamNameOnState) {
                    ctx.font = Chart.helpers.fontString(20, fontStyle, fontFamily)
                    ctx.fillText(chart.data.labels[index].substring(0, 4), position.x, position.y - (fontSize / 2) - padding + 50)
                  }
                }
              })
            }
          })
        }
      })
    },
    createWeb3 () {
      var web3 = new Web3(new Web3.providers.WebsocketProvider(this.$store.state.system.ethereumNode))
      this.pizzaCoin = new web3.eth.Contract(
        PizzaCoinAbi,
        this.$pizzaCoin.pizzaCoinAddr
      )
    },
    createChart (chartId, chartData) {
      if (chartData) {
        const ctx = document.getElementById(chartId)
        this.leaderBoardChart = new Chart(ctx, {
          type: chartData.type,
          data: chartData.data,
          options: chartData.options
        })
      }
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
        _.forEach(this.teams, (team, index) => {
          if (team.name === teamName) {
            this.leaderBoardChart.data.datasets[0].data[index] = totalVoted
            this.leaderBoardChart.update()
          }
        })
        console.log('***** Event catched *****')
        console.log('teamName: ' + teamName)
        console.log('totalVoted: ' + totalVoted)
      })

      return subscription
    }
  }
}
</script>
