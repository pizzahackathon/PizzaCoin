<template>
    <div class="home">
      <div class="container">
        <div class="is-mobile">
            <div>
                <div class="columns is-multiline">
                        <ProposalCard
                           v-for="proposal in proposals"
                           :key="proposal.groupId"
                           :proposal="proposal"
                          />
                </div>
            </div>
        </div>
      </div>
  </div>
</template>

<script>
import ProposalCard from '@/components/ProposalCard.vue'
import { mapGetters } from 'vuex'

export default {
  name: 'home',
  props: ['proposals'],
  computed: mapGetters(['proposals']),
  components: {
    ProposalCard
  },
  async mounted () {
    this.$store.dispatch('getProposal')
  }
}
</script>

<style>

</style>
