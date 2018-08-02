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
      </div>
  </div>
</template>

<script>
import ProposalCard from '@/components/ProposalCard.vue'
import { mapGetters, mapActions } from 'vuex'

export default {
  name: 'home',
  // props: ['proposals'],
  methods: {
    ...mapActions('team', ['getProposal'])
  },
  computed: {
    ...mapGetters('team', ['teams'])
  },
  components: {
    ProposalCard
  },
  async mounted () {
    this.getProposal()
  }
}
</script>

<style>

</style>
