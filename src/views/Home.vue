<template>
    <div class="home">
      <div class="container">
        <div class="is-mobile">
            <div>
                <div class="columns is-multiline">
                        <ProposalCard
                           v-for="member in members"
                           :key="member.groupId"
                           :proposal="member"
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
    ...mapGetters('team', ['members'])
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
