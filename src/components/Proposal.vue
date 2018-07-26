<template>
    <div>
        <div
            class="level is-mobile"
             v-for="member in members.detail"
             :key="member.address"
                >
            <div class="level-item has-text-centered">
                    <div>
                        <div>{{ member.name }}</div>
                    </div>
                </div>
                <div class="level-item has-text-centered">
                    <div>
                        <div>{{ member.address }}</div>
                    </div>
                </div>
                <div class="level-item has-text-centered">
                    <div>
                        <button
                            class="button is-danger"
                            @click="removeMember(member)"
                            >
                                Kick
                            </button>
                    </div>
            </div>
        </div>
        <button
            class="button is-primary"
             @click="onVote(members)"
            >VOTE</button>
    </div>
</template>
<script>
import { mapMutations } from 'vuex'

export default {
  props: ['members'],
  methods: {
    ...mapMutations(['removeMember']),
    onVote: function (members) {
      this.$store.commit('addScore', members)
    }
  }
}
</script>
