<template>
    <div class="web3Example">
      <div v-if="web3">
        web3 version {{ web3.version }}
      </div>
      <div>
        user address {{ userAddress }}
      </div>
      <div>
        Coin Name {{ pizzaCoinName }}
      </div>
      <div>
        Team count {{ teamCount }}
      </div>
      <hr />
      <strong> TEAM </strong>
      <div v-if="teamProfile">
        <div>
          Team name: {{ teamProfile._name }}
        </div>
        <div v-for="(memberAddress, i) in teamProfile._members" :key="memberAddress">
          Address {{ i }} {{ memberAddress }}
        </div>
        <div>
          Vote count {{ teamProfile._voteCount }}
        </div>

        <hr />
        <strong> Create Team </strong>
        <br />
        <div class="container">
          <b-field>
            <b-input v-model="teamName" placeholder="Team Name" rounded></b-input>
          </b-field>
          <b-field>
            <b-input v-model="memberName" placeholder="Member Name" rounded></b-input>
          </b-field>

          <p class="control">
            <button class="button is-primary" @click="createTeam()">Create</button>
          </p>
        </div>

        <hr />
        <strong> Logs </strong>
        <br />
        <b-table :data="newTeamLogs" :columns="columns"></b-table>
      </div>
  </div>
</template>

<script>
import Web3 from 'web3'
import pizzaCoinAbi from '@/abi/pizzaCoinAbi'

export default {
  name: 'Web3Example',
  data () {
    return {
      web3: null,
      userAddress: '',
      pizzaCoinAddress: '0xf13695158166ecbaed23ed689873481159a873e8',
      pizzaCoinContract: null,
      pizzaCoinName: '',
      teamCount: 0,
      teamProfile: null,
      teamName: '',
      memberName: '',
      newTeamLogs: [],

      columns: [
        {
          field: 'name',
          label: 'Name'
        },
        {
          field: 'teamIndex',
          label: 'Team Index'
        },
        {
          field: 'userAddress',
          label: 'User Address'
        }
      ]
    }
  },
  async mounted () {
    this.web3 = await this.createWeb3()
    this.loadPizzaCoinContract()
    this.getPizzaCoinName()
    this.getTeamCount()
    this.getTeamProfile(1)
    this.getNewTeamLogs()
  },
  methods: {
    async createWeb3 () {
      // Load web3 direct-inject
      if (undefined !== window.web3) {
        let web3js = window.web3
        let web3 = new Web3(web3js.currentProvider)

        let accounts = await web3.eth.getAccounts()
        this.userAddress = accounts[0]

        return web3
      } else {
        return new Web3(
          new Web3.providers.HttpProvider(
            'https://ropsten.infura.io/8kkr6X3gKuB8cURFQsfa'
          )
        )
      }
    },

    async getUserAddress () {
      let accounts = await this.web3.eth.getAccounts()
      this.userAddress = accounts[0]
    },

    async loadPizzaCoinContract () {
      this.pizzaCoinContract = new this.web3.eth.Contract(pizzaCoinAbi, this.pizzaCoinAddress)
    },

    async getPizzaCoinName () {
      this.pizzaCoinName = await this.pizzaCoinContract.methods.name().call()
    },

    async getTeamCount () {
      this.teamCount = await this.pizzaCoinContract.methods.teamCount().call()
    },

    async getTeamProfile (teamIndex) {
      this.teamProfile = await this.pizzaCoinContract.methods.teamProfile(teamIndex).call()
    },

    async createTeam () {
      let options = {
        from: this.userAddress
      }
      this.pizzaCoinContract.methods.newTeam(this.teamName, this.memberName).send(options)
    },

    async getNewTeamLogs () {
      let logs = await this.pizzaCoinContract.getPastEvents('NewMember', {
        fromBlock: 0,
        toBlock: 'latest'
      })
      this.newTeamLogs = logs.map(log => log.returnValues)
    }
  }
}
</script>

<style>

</style>
