<template>
    <div class="home">
      <div class="container">
        <div class="is-mobile">
            <div>
                <div class="columns is-multiline">
                        <ProposalCard
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
import ProposalCard from '@/components/ProposalCard.vue'
import { mapState } from 'vuex'

export default {
  data () {
    return {
      teamCount: ''
    }
  },
  name: 'home',
  // props: ['proposals'],
  computed: {
    ...mapState('team', ['teams'])
  },
  methods: {
    // ...mapActions('team', ['getProposal'])
  },
  components: {
    ProposalCard
  },
  async mounted () {
    try {
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
