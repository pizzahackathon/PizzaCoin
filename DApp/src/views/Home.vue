<template>
    <div class="home">
      <span style="
          text-align: center;
          justify-content: center;
          width: 100%;
          display: block;
          font-size: 4em;
          margin-bottom: 33px;
          margin-top: -27px;
        ">
        Teams
      </span>
      <div class="container">
        <div class="is-mobile">
            <div>
                <div class="columns is-multiline">
                    <TeamCard
                        v-for="team in teams"
                        :key="team.name"
                        :team="team"
                        :score="team.score"
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
      await this.$pizzaCoin.validateWeb3Connection(this.$toast)
      await this.$pizzaCoin.validateWallet(this.$toast)

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
