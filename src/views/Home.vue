<template>
    <div class="home">
      <div class="container">
        <div class="is-mobile">
            <div>
                <div class="columns is-multiline">
                        <ProposalCard
                           v-for="team in teams"
                           :key="team.groupId"
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
import { mapActions } from 'vuex'

export default {
  data () {
    return {
      teamCount: '',
      teams: []
    }
  },
  name: 'home',
  // props: ['proposals'],
  methods: {
    ...mapActions('team', ['getProposal'])
  },
  // computed: {
  //   ...mapGetters('team', ['teams'])
  // },
  components: {
    ProposalCard
  },
  async mounted () {
    this.getProposal()
    this.teamCount = await this.$pizzaCoin.getTeamCount()

    this.teams = await this.$pizzaCoin.getTeamsProfile()
  }
}
</script>

<style>

</style>
