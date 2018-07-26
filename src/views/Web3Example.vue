<template>
    <div class="web3Example">
      <div>
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
        <div>
          <label> Team Name </label>
          <input v-model="teamName" type="text" />
        </div>
        <div>
          <label> Member Name </label>
          <input v-model="memberName" type="text" />
        </div>
        <button @click="createTeam()">
          Create
        </button>
      </div>
  </div>
</template>

<script>
import Web3 from 'web3'
import pizzaCoinAbi from './pizzaCoinAbi'

export default {
  name: 'Web3Example',
  data () {
    return {
      web3: null,
      userAddress: '',
      pizzaCoinAddress: '0xb28bb961361e013a9eb8968991e2f6c84f213000',
      pizzaCoinContract: null,
      pizzaCoinName: '',
      teamCount: 0,
      teamProfile: null,
      teamName: '',
      memberName: ''
    }
  },
  async mounted () {
    this.$store.dispatch('getProposal')
    this.web3 = this.createWeb3()
    this.loadPizzaCoinContract()
    this.getPizzaCoinName()
    this.getTeamCount()
    this.getTeamProfile(1)
  },
  methods: {
    createWeb3 () {
      // Load web3 direct-inject
      if (undefined !== window.web3) {
        let web3js = window.web3
        let web3 = new Web3(web3js.currentProvider)

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
    }
  }
}
</script>

<style>

</style>
