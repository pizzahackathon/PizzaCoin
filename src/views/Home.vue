<template>
    <div class="home">
      <div class="container">
        <div class="is-mobile">
            <div>
                <div class="columns is-multiline">
                    <TeamCard
                        v-for="team in teams"
                        :key="team.name"
                        :team="team"
                      />
                </div>
            </div>
        </div>

        Team count {{ teamCount }}
      </div>
  </div>
</template>

<script>
import TeamCard from '@/components/TeamCard.vue'
import { mapState } from 'vuex'

export default {
  data () {
    return {
      teamCount: ''
    }
  },
  name: 'home',
  computed: {
    ...mapState('team', ['teams'])
  },
  methods: {
    async showToastSuccess (text) {
      this.$toast.open({
        message: text,
        type: 'is-success'
      })
    },
    async showToastError (text, duration = 5000) {
      this.$toast.open({
        duration: duration,
        message: text,
        // position: 'is-bottom',
        type: 'is-danger'
      })
    },
    async validateWeb3Connection () {
      // Check Web3 wallet connection
      if (typeof window.web3 === 'undefined') {
        const errorText = 'Please install MetaMask, Cipher or Trust wallet.'
        this.showToastError(errorText, 60000)
        throw Error(errorText)
      }

      // Check Network
      let currentNetwork = await this.$pizzaCoin.getNetworkName()
      console.log(`currentNetwork ${currentNetwork}`)
      if (currentNetwork !== 'rinkeby') {
        const errorText = 'Wrong network! Please switch to **Rinkeby** on Metamask.'
        this.showToastError(errorText, 60000)
        throw Error(errorText)
      }
    },
    async validateWallet () {
      let accounts = await this.$pizzaCoin.web3.eth.getAccounts()
      console.log(`accounts ${accounts}`)
      if (accounts.length === 0) {
        // Loop check if user unlocked then refresh
        setInterval(async () => {
          let accounts = await this.$pizzaCoin.web3.eth.getAccounts()
          if (accounts.length > 0) {
            console.log('refresh')
            location.reload()
          }
        }, 100)

        const errorText = 'Please unlock your MetaMask.'
        this.showToastError(errorText, 60000)
        throw Error(errorText)
      }
    }
  },
  components: {
    TeamCard
  },
  async created () {
    console.log('mounted' + this.teams)
  },
  async mounted () {
    try {
      // Web3 and Wallet validation
      await this.validateWeb3Connection()
      await this.validateWallet()

      this.teamCount = await this.$pizzaCoin.getTeamCount()
      this.$store.dispatch('team/getTeamsProfile', await this.$pizzaCoin.getTeamsProfile())
    } catch (error) {
      console.error(error)
    }
  }
}
</script>

<style>

</style>
